import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../../core/ui/working_center_banner.dart';
import '../data/intake_providers.dart';
import '../data/intake_repository.dart';
import '../domain/box_draft_input.dart';
import '../domain/intake_draft.dart';
import 'anonymous_exception_dialog.dart';
import 'box_draft_sheet.dart';
import 'campaign_sheet.dart';
import 'donor_sheet.dart';
import 'intake_queued_view.dart';
import 'intake_submitted_view.dart';

/// Captura de una donación, en una sola pantalla.
///
/// Todo el estado vive aquí: nada se pierde al retroceder y revisar antes de
/// enviar es mirar hacia abajo. La llave de idempotencia se generó al abrir y
/// no cambia, así que reenviar tras un rechazo nunca duplica inventario.
class IntakeFormView extends ConsumerStatefulWidget {
  const IntakeFormView({super.key, this.donationId});

  /// Donación pre-registrada de la que salió esta captura, cuando se llegó
  /// escaneando un código `DN-`.
  final String? donationId;

  static Route<void> route({String? donationId}) => MaterialPageRoute<void>(
    builder: (_) => IntakeFormView(donationId: donationId),
  );

  @override
  ConsumerState<IntakeFormView> createState() => _IntakeFormViewState();
}

class _IntakeFormViewState extends ConsumerState<IntakeFormView> {
  final _notes = TextEditingController();
  final _donanteLibre = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.donationId case final donationId?) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(intakeDraftControllerProvider.notifier)
              .prefillFromDonation(donationId);
        }
      });
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _donanteLibre.dispose();
    super.dispose();
  }

  IntakeDraftController get _controller =>
      ref.read(intakeDraftControllerProvider.notifier);

  Future<void> _addBox() async {
    final box = await BoxDraftSheet.show(context);
    if (box != null) _controller.addBox(box);
  }

  Future<void> _pickCampaign(List<CampaignOut> campaigns) async {
    final chosen = await CampaignSheet.show(
      context,
      campaigns: campaigns,
      selected: ref.read(intakeDraftControllerProvider).campaignId,
    );
    if (chosen != null) _controller.setCampaign(chosen.id);
  }

  Future<void> _editBox(int index, BoxDraftInput current) async {
    final box = await BoxDraftSheet.show(context, initial: current);
    if (box != null) _controller.replaceBox(index, box);
  }

  Future<bool> _identifyDonor() async {
    final draft = ref.read(intakeDraftControllerProvider);
    final result = await DonorSheet.show(
      context,
      initial: draft.donor,
      termsAccepted: draft.donorTermsAccepted,
    );
    if (result == null) return false;

    _controller.setDonor(result.donor, termsAccepted: result.termsAccepted);
    return true;
  }

  Future<void> _submit() async {
    _controller
      ..setNotes(_notes.text)
      ..setDonanteLibre(_donanteLibre.text);

    final userId = ref.read(currentUserIdProvider);
    final offline =
        ref.read(connectivityControllerProvider) == ConnectivityStatus.offline;

    // Sin señal no se intenta y se falla: se encola. Es la única escritura que
    // depende solo de lo que la persona tiene enfrente, y por eso es la única
    // que puede esperar en el dispositivo.
    if (offline && userId != null) {
      await _enqueue(userId);
      return;
    }

    var result = await _send();

    // El servidor puede pedir identificar a quien dona. No es un error de
    // campo: es una pregunta para el mostrador, y la respuesta se reenvía con
    // la misma llave de captura.
    if (result is IntakeNeedsDonor && mounted) {
      final resolved = await _resolveDonorRequest(result);
      result = resolved ?? result;
    }

    if (!mounted) return;

    switch (result) {
      case IntakeAccepted(:final intake):
        await Navigator.of(
          context,
        ).pushReplacement(IntakeSubmittedView.route(intake));
      // Un rechazo se muestra con el motivo del servidor. Que la pregunta por
      // el donante llegue hasta aquí significa que quedó sin resolver, y esa
      // también es una respuesta que quien captura tiene que leer.
      case IntakeNeedsDonor(:final failure):
        _showFailure(failure.operatorMessage(context.l10n));
      // La red se cayó a mitad del envío. Perder lo capturado sería el peor
      // resultado posible, así que la captura pasa a la cola con su misma
      // llave: cuando salga la señal se enviará una vez, no dos.
      case IntakeRejected(:final failure)
          when failure.isRetryable && userId != null:
        await _enqueue(userId);
      case IntakeRejected(:final failure):
        _showFailure(failure.operatorMessage(context.l10n));
    }
  }

  /// Guarda la captura para enviarla al recuperar la señal, asignándole antes
  /// los códigos reservados que hagan falta para poder etiquetar ahora.
  Future<void> _enqueue(String userId) async {
    setState(() => _submitting = true);

    final draft = ref.read(intakeDraftControllerProvider);
    final withoutCode = draft.boxes.where((box) => box.code == null).length;
    if (withoutCode > 0) {
      final codes = await ref
          .read(boxCodeRepositoryProvider)
          .take(
            withoutCode,
            userId: userId,
            centerId: ref.read(writeCenterIdProvider),
          );
      _controller.assignCodes(codes);
    }

    await _controller.enqueue(userId);
    if (!mounted) return;

    setState(() => _submitting = false);
    await Navigator.of(context).pushReplacement(
      IntakeQueuedView.route(ref.read(intakeDraftControllerProvider)),
    );
  }

  /// Envía y marca la pantalla como ocupada solo mientras la petición está en
  /// vuelo. Esperar a que alguien conteste un diálogo no es estar enviando, y
  /// dejar el indicador girando mientras tanto diría lo contrario.
  Future<IntakeSubmission> _send() async {
    setState(() => _submitting = true);
    final result = await _controller.submit();
    if (mounted) setState(() => _submitting = false);
    return result;
  }

  Future<IntakeSubmission?> _resolveDonorRequest(IntakeNeedsDonor asked) async {
    final decision = await AnonymousExceptionDialog.show(
      context,
      serverMessage: asked.failure.operatorMessage(context.l10n),
    );
    if (decision == null || !mounted) return null;

    switch (decision.outcome) {
      case DonorRequestOutcome.identify:
        if (!await _identifyDonor()) return null;
      case DonorRequestOutcome.exception:
        _controller.setExceptionReason(decision.reason);
    }

    return _send();
  }

  void _showFailure(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(intakeDraftControllerProvider);
    final campaigns = ref.watch(myCampaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _CampaignHeader(
          label: _campaignLabel(
            context.l10n,
            campaigns.valueOrNull,
            draft.campaignId,
          ),
          onTap: () => _pickCampaign(campaigns.valueOrNull ?? const []),
        ),
      ),
      body: Column(
        children: [
          const WorkingCenterBanner(),
          Expanded(
            child: AbsorbPointer(
              absorbing: _submitting,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_submitting) const LinearProgressIndicator(),
                  if (draft.donationId != null) const _DonationNotice(),
                  _DonorSection(
                    draft: draft,
                    onIdentify: _identifyDonor,
                    onClear: _controller.clearDonor,
                    donanteLibre: _donanteLibre,
                  ),
                  const SizedBox(height: 16),
                  _BoxesCard(
                    boxes: draft.boxes,
                    onEdit: _editBox,
                    onRemove: _controller.removeBox,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: context.l10n.notesOptionalLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Las dos acciones viven abajo y no se van con el desplazamiento: añadir
      // caja es lo que más se repite, y registrar es lo que cierra. Buscarlas
      // hacia arriba, con una caja en las manos, era el peor sitio para ambas.
      bottomNavigationBar: _ActionBar(
        onAdd: _submitting ? null : _addBox,
        onSubmit: draft.isSubmittable && !_submitting ? _submit : null,
      ),
    );
  }

  /// Nombre de la campaña activa. Mientras la lista no llega no se puede
  /// resolver un identificador a un nombre, y decir «general» sin saberlo sería
  /// afirmar algo falso justo en la línea que da el contexto.
  static String _campaignLabel(
    AppLocalizations l10n,
    List<CampaignOut>? campaigns,
    String? id,
  ) {
    if (id == null) return l10n.generalCampaign;
    if (campaigns == null) return l10n.campaignPlaceholder;
    for (final campaign in campaigns) {
      if (campaign.id == id) return campaign.name;
    }
    return l10n.generalCampaign;
  }
}

/// Título de la pantalla con la campaña debajo, tocable para cambiarla.
class _CampaignHeader extends StatelessWidget {
  const _CampaignHeader({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.intakeFormTitle),
        InkWell(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const Icon(Icons.expand_more, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra fija con las dos acciones: azul lleva a otra pantalla, dorado cierra.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onAdd, required this.onSubmit});

  final VoidCallback? onAdd;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.bar,
        border: Border(top: BorderSide(color: palette.barBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Una barra inferior no sube con el teclado por sí sola, y aquí se
          // escribe con el pulgar mientras se sostiene una caja.
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  child: Text(context.l10n.boxAddAction),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ConfirmButton(
                  label: context.l10n.registerAction,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationNotice extends StatelessWidget {
  const _DonationNotice();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        context.l10n.captureLinkedToDonation,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

class _DonorSection extends StatelessWidget {
  const _DonorSection({
    required this.draft,
    required this.onIdentify,
    required this.onClear,
    required this.donanteLibre,
  });

  final IntakeDraft draft;
  final Future<bool> Function() onIdentify;
  final VoidCallback onClear;
  final TextEditingController donanteLibre;

  @override
  Widget build(BuildContext context) {
    if (draft.donor case final donor?) {
      return Card(
        child: Column(
          children: [
            RecordField(
              label: donor.donorType == DonorType.legal ? 'Empresa' : 'Persona',
              value: donor.legalName ?? '${donor.firstName} ${donor.lastName}',
            ),
            OverflowBar(
              children: [
                TextButton(
                  onPressed: onClear,
                  child: Text(context.l10n.removeAction),
                ),
                TextButton(
                  onPressed: () => onIdentify(),
                  child: Text(context.l10n.centerEditAction),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: donanteLibre,
          decoration: InputDecoration(
            labelText: context.l10n.donorOptionalLabel,
            helperText: context.l10n.freeNameHint,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => onIdentify(),
          icon: const Icon(Icons.person_add_alt),
          label: Text(context.l10n.identifyDonorTitle),
        ),
      ],
    );
  }
}

/// Lo que lleva la entrada hasta ahora, con su recuento.
///
/// El número va en el encabezado porque es lo que se comprueba antes de
/// registrar: quien recibió seis bultos cuenta seis líneas, y una tarjeta que
/// solo las enumera obliga a contarlas a ojo.
class _BoxesCard extends StatelessWidget {
  const _BoxesCard({
    required this.boxes,
    required this.onEdit,
    required this.onRemove,
  });

  final List<BoxDraftInput> boxes;
  final void Function(int index, BoxDraftInput box) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.boxesInIntake(boxes.length),
              style: theme.textTheme.titleMedium,
            ),
            if (boxes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
                child: Text(
                  context.l10n.captureNeedsBoxes,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            for (final (index, box) in boxes.indexed)
              _BoxRow(
                box: box,
                onEdit: () => onEdit(index, box),
                onRemove: () => onRemove(index),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoxRow extends StatelessWidget {
  const _BoxRow({
    required this.box,
    required this.onEdit,
    required this.onRemove,
  });

  final BoxDraftInput box;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(box.productType.displayName),
    subtitle: Text(
      [
        // El código solo existe cuando se reservó para etiquetar sin señal. Es
        // lo primero de la línea porque es lo que está escrito en el cartón
        // que la persona tiene delante.
        ?box.code,
        '${box.quantity} ${box.unit}',
        if (box.batch case final batch?) 'lote $batch',
        if (box.expiryDate case final expiry?)
          'vence ${formatShortDate(expiry)}',
      ].join(' · '),
    ),
    onTap: onEdit,
    trailing: IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: context.l10n.boxRemoveTitle,
      onPressed: onRemove,
    ),
  );
}
