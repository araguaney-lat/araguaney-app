import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_application_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/relative_time.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/ui/center_record_view.dart';
import '../data/center_applications_providers.dart';
import '../data/center_applications_repository.dart';
import 'reject_application_sheet.dart';

/// La cola de postulaciones de centro.
///
/// **Es el otro extremo del enlace del acceso.** La aplicación manda a quien no
/// tiene centro a postular en la web; esto es donde alguien contesta. Una cola
/// cuyo propósito entero es no atascarse es exactamente lo que vale la pena
/// tener en un teléfono: lo que cuesta que se quede parada es un centro que no
/// puede empezar a operar.
///
/// Solo trae lo que espera revisión, de lo más viejo a lo más nuevo. Decidir
/// una la saca de aquí, así que esto es una cola y no un historial.
class ApplicationQueueView extends ConsumerStatefulWidget {
  const ApplicationQueueView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ApplicationQueueView());

  @override
  ConsumerState<ApplicationQueueView> createState() =>
      _ApplicationQueueViewState();
}

class _ApplicationQueueViewState extends ConsumerState<ApplicationQueueView> {
  String? _deciding;

  Future<void> _approve(CenterApplicationOut application) async {
    // Se toma antes de abrir el diálogo: después de esperarlo, este contexto
    // puede haber dejado de estar montado.
    final l10n = context.l10n;
    // Aprobar hace tres cosas irreversibles desde aquí, así que se nombran las
    // tres antes de hacerlas. Una confirmación que solo dice «¿seguro?» no
    // informa de nada.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.applicationApproveConfirmTitle(application.centerName),
        ),
        content: Text(
          context.l10n.applicationApproveExplanation(
            application.contactName,
            application.contactEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.actionApprove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _decide(
      application.id,
      () => ref
          .read(centerApplicationsRepositoryProvider)
          .approve(application.id),
      done: l10n.applicationApproved(application.centerName),
      // Aprobar crea un centro, y `created_center_id` viene en la respuesta.
      // Ofrecerlo cierra el paso siguiente real: quien acaba de aprobar suele
      // querer mirar —o corregir— lo que se acaba de crear, con la postulación
      // todavía en la cabeza.
      onCreated: (resolved) {
        final id = resolved.createdCenterId;
        if (id == null) return null;
        return (
          label: context.l10n.applicationViewCenter,
          route: CenterRecordView.route(id),
        );
      },
    );
  }

  Future<void> _reject(CenterApplicationOut application) async {
    final l10n = context.l10n;
    final reason = await RejectApplicationSheet.show(
      context,
      centerName: application.centerName,
    );
    if (reason == null) return;

    await _decide(
      application.id,
      () => ref
          .read(centerApplicationsRepositoryProvider)
          .reject(application.id, reason),
      done: l10n.applicationRejected(application.contactName),
    );
  }

  Future<void> _decide(
    String id,
    Future<ApplicationsOutcome<CenterApplicationOut>> Function() run, {
    required String done,
    ({String label, Route<void> route})? Function(CenterApplicationOut)?
    onCreated,
  }) async {
    setState(() => _deciding = id);
    final outcome = await run();
    if (!mounted) return;
    setState(() => _deciding = null);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    switch (outcome) {
      case ApplicationsRead(:final value):
        ref.invalidate(applicationQueueProvider);
        // El centro nuevo también: la lista de centros tiene que tenerlo.
        ref.invalidate(centersProvider);
        final next = onCreated?.call(value);
        messenger.showSnackBar(
          SnackBar(
            content: Text(done),
            action: next == null
                ? null
                : SnackBarAction(
                    label: next.label,
                    onPressed: () => navigator.push(next.route),
                  ),
          ),
        );
      case ApplicationsRefused(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(applicationQueueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.applicationsTitle)),
      body: switch (queue) {
        AsyncData(value: ApplicationsRead(:final value)) when value.isEmpty =>
          _Message(context.l10n.applicationsEmpty),
        AsyncData(value: ApplicationsRead(:final value)) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(applicationQueueProvider),
          child: ListView(
            children: [
              _Header(pending: value.length),
              for (final application in value)
                _ApplicationCard(
                  application: application,
                  busy: _deciding == application.id,
                  onApprove: () => _approve(application),
                  onReject: () => _reject(application),
                ),
            ],
          ),
        ),
        AsyncData(
          value: ApplicationsRefused(:final isForbidden, :final failure),
        ) =>
          _Message(
            isForbidden
                ? 'Solo quien revisa postulaciones puede ver esta cola.'
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.pending});

  final int pending;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      context.l10n.applicationsPendingCount(pending),
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final CenterApplicationOut application;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final place = [
      application.stateName,
      application.countryCode,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(application.centerName, style: text.titleMedium),
                ),
                Text(
                  describeAge(application.createdAt, DateTime.now()),
                  style: text.bodySmall,
                ),
              ],
            ),
            if (place.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(place, style: text.bodyMedium),
              ),
            const SizedBox(height: 12),
            // Todo lo que la decisión necesita, en la tarjeta. Obligar a abrir
            // una ficha para saber quién respalda un centro convierte una cola
            // de tres en tres navegaciones.
            RecordField(
              label: context.l10n.contactLabel,
              value: '${application.contactName} · ${application.contactEmail}',
            ),
            if (application.contactPhone case final phone?
                when phone.isNotEmpty)
              RecordField(label: context.l10n.phoneLabel, value: phone),
            if (application.address case final address? when address.isNotEmpty)
              RecordField(label: context.l10n.addressLabel, value: address),
            if (application.backingOrg case final org? when org.isNotEmpty)
              RecordField(label: context.l10n.backingOrgLabel, value: org),
            if (application.socialUrl case final social? when social.isNotEmpty)
              RecordField(label: context.l10n.socialLabel, value: social),
            if (application.message case final message?
                when message.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Entre comillas y sin editar: son las palabras de quien postuló.
              Text('«$message»', style: text.bodyMedium),
            ],
            const SizedBox(height: 16),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      child: Text(context.l10n.actionApprove),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: Text(context.l10n.actionReject),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
    child: Text(text, textAlign: TextAlign.center),
  );
}
