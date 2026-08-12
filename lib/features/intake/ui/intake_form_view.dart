import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/ui/record_field.dart';
import '../data/intake_providers.dart';
import '../data/intake_repository.dart';
import '../domain/box_draft_input.dart';
import '../domain/intake_draft.dart';
import 'anonymous_exception_dialog.dart';
import 'box_draft_sheet.dart';
import 'donor_sheet.dart';
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
        _showFailure(failure.operatorMessage);
      case IntakeRejected(:final failure):
        _showFailure(failure.operatorMessage);
    }
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
      serverMessage: asked.failure.operatorMessage,
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
    final campaigns = ref.watch(myCampaignsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva captura'),
        actions: [
          TextButton(
            onPressed: draft.isSubmittable && !_submitting ? _submit : null,
            child: const Text('Enviar'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (draft.donationId != null) const _DonationNotice(),
            _CampaignField(
              campaigns: campaigns,
              selected: draft.campaignId,
              onChanged: _controller.setCampaign,
            ),
            const SizedBox(height: 16),
            _DonorSection(
              draft: draft,
              onIdentify: _identifyDonor,
              onClear: _controller.clearDonor,
              donanteLibre: _donanteLibre,
            ),
            const SizedBox(height: 24),
            _BoxesSection(
              boxes: draft.boxes,
              onAdd: _addBox,
              onEdit: _editBox,
              onRemove: _controller.removeBox,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
            const SizedBox(height: 24),
            if (_submitting) const LinearProgressIndicator(),
          ],
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
        'Esta captura queda ligada a la donación que escaneaste. Registra lo '
        'que llegó: lo que declaró quien donó es otra cosa.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

class _CampaignField extends StatelessWidget {
  const _CampaignField({
    required this.campaigns,
    required this.selected,
    required this.onChanged,
  });

  final List<CampaignOut> campaigns;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: selected,
    decoration: const InputDecoration(
      labelText: 'Campaña',
      helperText: 'Sin campaña la donación queda en la general',
    ),
    items: [
      const DropdownMenuItem(child: Text('Sin campaña')),
      for (final campaign in campaigns)
        DropdownMenuItem(value: campaign.id, child: Text(campaign.name)),
    ],
    onChanged: onChanged,
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
                TextButton(onPressed: onClear, child: const Text('Quitar')),
                TextButton(
                  onPressed: () => onIdentify(),
                  child: const Text('Editar'),
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
          decoration: const InputDecoration(
            labelText: 'Donante (opcional)',
            helperText: 'Un nombre suelto, sin registrar a la persona',
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => onIdentify(),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Identificar donante'),
        ),
      ],
    );
  }
}

class _BoxesSection extends StatelessWidget {
  const _BoxesSection({
    required this.boxes,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<BoxDraftInput> boxes;
  final VoidCallback onAdd;
  final void Function(int index, BoxDraftInput box) onEdit;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cajas', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (boxes.isEmpty)
        Text(
          'Todavía no agregaste ninguna caja. Sin cajas no hay captura.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      for (final (index, box) in boxes.indexed)
        Card(
          child: ListTile(
            title: Text(box.productType.displayName),
            subtitle: Text(
              [
                '${box.quantity} ${box.unit}',
                if (box.batch case final batch?) 'lote $batch',
                if (box.expiryDate case final expiry?)
                  'vence ${formatShortDate(expiry)}',
              ].join(' · '),
            ),
            onTap: () => onEdit(index, box),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Quitar caja',
              onPressed: () => onRemove(index),
            ),
          ),
        ),
      const SizedBox(height: 8),
      FilledButton.tonalIcon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Agregar caja'),
      ),
    ],
  );
}
