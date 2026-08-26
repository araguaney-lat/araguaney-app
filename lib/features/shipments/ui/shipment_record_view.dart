import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/export_job.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/api/generated/models/reception_out.dart';
import '../../../core/api/generated/models/shipment_detail_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/platform/open_link.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../incidents/data/incidents_providers.dart';
import '../../incidents/data/incidents_repository.dart';
import '../../incidents/ui/report_incident_sheet.dart';
import '../../pallets/data/pallets_providers.dart';
import '../../reports/ui/reports_view.dart';
import '../data/shipments_providers.dart';
import '../data/shipments_repository.dart';
import 'add_milestone_sheet.dart';
import 'pick_pallet_sheet.dart';
import 'register_reception_view.dart';

/// A shipment's record, read-only, with what arrived and what did not.
///
/// It came before the rest of phase 10 because a delivery notice needed
/// somewhere to land. Now it tells the whole story from the sending centre's
/// side: the reception says what arrived well, the incidents what did not, and
/// raising one is the only thing written from here.
final shipmentProvider = FutureProvider.family<ShipmentDetailOut, String>(
  (ref, id) => ref
      .watch(restClientProvider)
      .shipments
      .getShipmentV1ShipmentsShipmentIdGet(shipmentId: id),
);

class ShipmentRecordView extends ConsumerWidget {
  const ShipmentRecordView({super.key, required this.shipmentId});

  final String shipmentId;

  static Route<void> route(String shipmentId) => MaterialPageRoute<void>(
    builder: (_) => ShipmentRecordView(shipmentId: shipmentId),
  );

  /// Asks for the manifest and opens it.
  ///
  /// The server does not return the PDF: it returns a job, and the document
  /// arrives when it finishes being assembled. If it takes longer than this
  /// polling waits, that is said — the job is still alive over there and asking
  /// again picks it up.
  Future<void> _document(
    BuildContext context,
    WidgetRef ref,
    ShipmentDocument document,
  ) async {
    // Taken before waiting: after an await this context may have stopped being
    // mounted.
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context)
      ..showSnackBar(SnackBar(content: Text(l10n.manifestPreparing)));

    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .document(shipmentId, document);
    if (!context.mounted) return;

    // The waiting notice is withdrawn before saying how it ended: otherwise
    // the answer queues up behind it and arrives when nobody is looking.
    messenger.hideCurrentSnackBar();

    switch (outcome) {
      case DocumentReady(:final downloadUrl):
        final opened = await ref.read(openLinkProvider)(downloadUrl);
        if (!opened) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.manifestOpenFailed)),
          );
        }
      case DocumentStillWorking():
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.manifestStillWorking)),
        );
      case DocumentFailed(:final failure, :final serverError):
        // The call's failure wins; if there was none, the server's words; and
        // if not those either, the only thing that can be said for certain.
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failure?.operatorMessage(l10n) ??
                  serverError ??
                  l10n.manifestFailed,
            ),
          ),
        );
    }
  }

  /// Records a milestone and leaves it in the journey, which already knew how
  /// to read them.
  Future<void> _milestone(BuildContext context, WidgetRef ref) async {
    final chosen = await AddMilestoneSheet.show(context);
    if (chosen == null || !context.mounted) return;

    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .addMilestone(
          shipmentId: shipmentId,
          milestone: chosen.milestone,
          note: chosen.note,
          occurredAt: chosen.occurredAt,
        );
    if (!context.mounted) return;

    switch (outcome) {
      case ShipmentDone():
        ref
          ..invalidate(shipmentProvider(shipmentId))
          ..invalidate(shipmentEventsProvider(shipmentId));
      case ShipmentRefused(:final failure):
        _say(context, failure.operatorMessage(context.l10n));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipment = ref.watch(shipmentProvider(shipmentId));
    final canReport = ref.watch(isCenterCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          shipment.valueOrNull?.reference ?? context.l10n.shipmentRecordTitle,
        ),
        actions: [
          // Recording a milestone requires national administration, like
          // delivering and like the reception. It is offered whenever the role
          // allows it: the server accepts a milestone in any state, and putting
          // a condition of our own here would be inventing a rule of its.
          if (ref.watch(isNationalAdminProvider))
            IconButton(
              tooltip: context.l10n.milestoneAddTitle,
              icon: const Icon(Icons.add_location_alt_outlined),
              onPressed: () => _milestone(context, ref),
            ),
          PopupMenuButton<ShipmentDocument>(
            tooltip: context.l10n.shipmentDocuments,
            icon: const Icon(Icons.description_outlined),
            onSelected: (document) => _document(context, ref, document),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ShipmentDocument.manifestPdf,
                child: Text(context.l10n.documentManifestPdf),
              ),
              PopupMenuItem(
                value: ShipmentDocument.manifestXlsx,
                child: Text(context.l10n.documentManifestXlsx),
              ),
              PopupMenuItem(
                value: ShipmentDocument.declarationJson,
                child: Text(context.l10n.documentDeclarationJson),
              ),
              PopupMenuItem(
                value: ShipmentDocument.declarationXlsx,
                child: Text(context.l10n.documentDeclarationXlsx),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: canReport
          ? FloatingActionButton.extended(
              onPressed: () => reportShipmentIncident(context, ref, shipmentId),
              icon: const Icon(Icons.report_outlined),
              label: Text(context.l10n.incidentLabel),
            )
          : null,
      bottomNavigationBar: switch (shipment) {
        AsyncData(:final value) when canReport => _Advance(shipment: value),
        _ => null,
      },
      body: switch (shipment) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(shipmentProvider(shipmentId))
              ..invalidate(shipmentReceptionProvider(shipmentId))
              ..invalidate(shipmentEventsProvider(shipmentId))
              ..invalidate(shipmentIncidentsProvider(shipmentId));
          },
          child: _Body(shipment: value, shipmentId: shipmentId),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.shipment, required this.shipmentId});

  final ShipmentDetailOut shipment;
  final String shipmentId;

  /// Adding a pallet. It is chosen from the closed ones that are not already
  /// travelling in another shipment; the sheet does the filtering, and the
  /// server checks it again.
  Future<void> _addPallet(
    BuildContext context,
    WidgetRef ref,
    ShipmentDetailOut shipment,
  ) async {
    final pallet = await PickPalletSheet.show(
      context,
      alreadyIn: {for (final p in shipment.pallets) p.id},
    );
    if (pallet == null || !context.mounted) return;

    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .addPallet(shipmentId: shipment.id, palletId: pallet.id);
    if (!context.mounted) return;

    if (outcome case ShipmentRefused(:final failure)) {
      _say(context, failure.operatorMessage(context.l10n));
      return;
    }
    ref
      ..invalidate(shipmentProvider(shipmentId))
      ..invalidate(palletsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reception = ref.watch(shipmentReceptionProvider(shipmentId));
    final incidents = ref.watch(shipmentIncidentsProvider(shipmentId));
    final events = ref.watch(shipmentEventsProvider(shipmentId));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        RecordField(
          label: context.l10n.statusLabel,
          value: shipmentStatusLabel(context.l10n, shipment.status),
        ),
        RecordField(
          label: context.l10n.destinationLabel,
          value: shipment.destination,
        ),
        if (shipment.carrier case final carrier?)
          RecordField(label: context.l10n.carrierLabel, value: carrier),
        RecordField(
          label: context.l10n.palletsTitle,
          value: '${shipment.pallets.length}',
        ),
        if (shipment.shippedAt case final shipped?)
          RecordField(
            label: context.l10n.shipmentStatusShipped,
            value: formatShortDate(shipped),
          ),
        if (shipment.deliveredAt case final delivered?)
          RecordField(
            label: context.l10n.shipmentStatusDelivered,
            value: formatShortDate(delivered),
          ),
        if (shipment.notes case final notes?)
          RecordField(label: context.l10n.notesLabel, value: notes),
        // The height warnings are computed by the server against the
        // shipment's profile, and they warn without blocking. The application
        // repeats them as they are: the threshold is its own and nothing is
        // interpreted here.
        for (final warning in shipment.heightWarnings) _Note(warning),
        const Divider(),
        _SectionTitle(context.l10n.palletsTitle),
        if (shipment.pallets.isEmpty) _Note(context.l10n.shipmentNoPallets),
        for (final pallet in shipment.pallets)
          _PalletRow(
            pallet: pallet,
            shipmentId: shipmentId,
            removable: shipment.status == 'OPEN',
          ),
        if (shipment.status == 'OPEN')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () => _addPallet(context, ref, shipment),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.shipmentAddPallet),
            ),
          ),
        const Divider(),
        _SectionTitle(context.l10n.receptionHeading),
        switch (reception) {
          AsyncData(value: final value?) => _Reception(
            reception: value,
            campaignId: shipment.campaignId,
          ),
          AsyncData() => _Note(context.l10n.receptionNotRegistered),
          AsyncError() => _Note(context.l10n.receptionUnavailable),
          _ => _Note(context.l10n.loadingShort),
        },
        const Divider(),
        _SectionTitle(context.l10n.timelineHeading),
        switch (events) {
          AsyncData(:final value) when value.isEmpty => _Note(
            context.l10n.milestonesEmpty,
          ),
          AsyncData(:final value) => Column(
            children: [for (final event in value) _Event(event: event)],
          ),
          AsyncError() => _Note(context.l10n.timelineUnavailable),
          _ => _Note(context.l10n.loadingShort),
        },
        const Divider(),
        _SectionTitle(context.l10n.incidentsTitle),
        switch (incidents) {
          AsyncData(:final value) when value.isEmpty => _Note(
            context.l10n.incidentsEmptyForShipment,
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final incident in value) _Incident(incident: incident),
            ],
          ),
          AsyncError() => _Note(context.l10n.incidentsUnavailable),
          _ => _Note(context.l10n.loadingShort),
        },
        const SizedBox(height: 80),
      ],
    );
  }
}

/// A pallet inside the shipment.
class _PalletRow extends ConsumerWidget {
  const _PalletRow({
    required this.pallet,
    required this.shipmentId,
    required this.removable,
  });

  final PalletDetailOut pallet;
  final String shipmentId;

  /// Only while the shipment is still open. Once closed it takes no more
  /// changes, and offering a button the server is going to refuse is worse than
  /// not having it.
  final bool removable;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    title: Text(pallet.code),
    subtitle: Text(
      [
        '${pallet.boxes.length} '
            '${pallet.boxes.length == 1 ? 'caja' : 'cajas'}',
        if (pallet.heightCm case final height?) '$height cm',
        if (pallet.grossWeightKg case final weight?) '$weight kg',
      ].join(' · '),
    ),
    trailing: removable
        ? IconButton(
            tooltip: context.l10n.shipmentRemovePalletTooltip,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _remove(context, ref),
          )
        : null,
  );

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .removePallet(shipmentId: shipmentId, palletId: pallet.id);
    if (!context.mounted) return;

    if (outcome case ShipmentRefused(:final failure)) {
      _say(context, failure.operatorMessage(context.l10n));
      return;
    }
    ref
      ..invalidate(shipmentProvider(shipmentId))
      ..invalidate(palletsProvider);
  }
}

/// The only thing that can be moved forward from here, and only the next step.
///
/// Closing stops accepting pallets; dispatching says the shipment left. Both go
/// one way only and the server does not undo them, so both ask first and name
/// what is at stake.
class _Advance extends ConsumerStatefulWidget {
  const _Advance({required this.shipment});

  final ShipmentDetailOut shipment;

  @override
  ConsumerState<_Advance> createState() => _AdvanceState();
}

class _AdvanceState extends ConsumerState<_Advance> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    // Closing and dispatching belong to the sending centre; delivering and
    // recording the reception require national administration. That is how the
    // server splits the four steps, and the bar does not offer what it is going
    // to answer 403 to.
    final national = ref.watch(isNationalAdminProvider);
    final reception = ref
        .watch(shipmentReceptionProvider(widget.shipment.id))
        .valueOrNull;

    final label = switch (widget.shipment.status) {
      'OPEN' => context.l10n.shipmentCloseAction,
      'CLOSED' => context.l10n.shipmentDispatchAction,
      'SHIPPED' when national => context.l10n.shipmentDeliveredAction,
      // The reception is recorded once only: with one already written the step
      // disappears instead of failing with a 409.
      'DELIVERED' when national && reception == null =>
        context.l10n.receptionRegisterAction,
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ConfirmButton(
            label: label,
            onPressed: _busy ? null : () => _advance(label),
          ),
        ),
      ),
    );
  }

  Future<void> _advance(String label) async {
    final shipment = widget.shipment;

    // Recording the reception is not a one-button step: it is a screen, box by
    // box.
    if (shipment.status == 'DELIVERED') {
      final registered = await Navigator.of(
        context,
      ).push(RegisterReceptionView.route(shipment));
      if (!mounted || !(registered ?? false)) return;
      ref
        ..invalidate(shipmentProvider(shipment.id))
        ..invalidate(shipmentReceptionProvider(shipment.id))
        ..invalidate(shipmentIncidentsProvider(shipment.id))
        ..invalidate(shipmentEventsProvider(shipment.id));
      return;
    }

    if (shipment.status == 'SHIPPED') {
      await _markDelivered(shipment);
      return;
    }

    final closing = shipment.status == 'OPEN';
    final pallets = shipment.pallets.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          closing
              ? context.l10n.shipmentCloseConfirmTitle
              : context.l10n.shipmentDispatchConfirmTitle,
        ),
        content: Text(
          closing
              ? context.l10n.shipmentCloseExplanation(
                  pallets,
                  shipment.destination,
                )
              : context.l10n.shipmentDispatchExplanation(
                  pallets,
                  shipment.destination,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.notYetValue),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              closing
                  ? context.l10n.actionClose
                  : context.l10n.shipmentDispatchAction,
            ),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _busy = true);
    final repository = ref.read(shipmentsRepositoryProvider);
    final outcome = closing
        ? await repository.close(shipment.id)
        : await repository.ship(shipment.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (outcome case ShipmentRefused(:final failure)) {
      _say(context, failure.operatorMessage(context.l10n));
      return;
    }
    ref
      ..invalidate(shipmentProvider(shipment.id))
      ..invalidate(shipmentsProvider)
      ..invalidate(shipmentEventsProvider(shipment.id));
  }

  /// `SHIPPED` → `DELIVERED`.
  ///
  /// It says it arrived and nothing more: **what** arrived is recorded by the
  /// reception, which is the next step. Saying both things with one button
  /// would declare received what nobody has counted yet.
  Future<void> _markDelivered(ShipmentDetailOut shipment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.shipmentDeliveredTitle),
        content: Text(context.l10n.shipmentDeliveredExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.notYetValue),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.shipmentDeliveredAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _busy = true);
    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .markDelivered(shipmentId: shipment.id);
    if (!mounted) return;
    setState(() => _busy = false);

    if (outcome case ShipmentRefused(:final failure)) {
      _say(context, failure.operatorMessage(context.l10n));
      return;
    }
    ref
      ..invalidate(shipmentProvider(shipment.id))
      ..invalidate(shipmentsProvider)
      ..invalidate(shipmentEventsProvider(shipment.id));
  }
}

/// Raising an incident about this shipment.
///
/// Two places call it: the floating button, and what the reception found —
/// which is where somebody has just seen that the boxes do not add up.
Future<void> reportShipmentIncident(
  BuildContext context,
  WidgetRef ref,
  String shipmentId,
) async {
  final incident = await ReportIncidentSheet.show(context);
  if (incident == null || !context.mounted) return;

  final outcome = await ref
      .read(incidentsRepositoryProvider)
      .create(
        shipmentId: shipmentId,
        type: incident.type,
        description: incident.description,
      );
  if (!context.mounted) return;

  switch (outcome) {
    case IncidentCreated():
      ref.invalidate(shipmentIncidentsProvider(shipmentId));
    case IncidentRejected(:final failure):
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.operatorMessage(context.l10n))),
      );
  }
}

void _say(BuildContext context, String message) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(message)));

class _Reception extends StatelessWidget {
  const _Reception({required this.reception, this.campaignId});

  final ReceptionOut reception;

  /// The shipment's campaign, so its shrinkage can be looked at from here.
  final String? campaignId;

  @override
  Widget build(BuildContext context) {
    final shrinkage = reception.shrinkage;

    return Column(
      children: [
        RecordField(
          label: context.l10n.donationStatusReceived,
          value: formatShortDate(reception.receivedAt),
        ),
        if (reception.consigneeName case final consignee?)
          RecordField(label: context.l10n.receivedByLabel, value: consignee),
        RecordField(
          label: context.l10n.boxesTitle,
          value: context.l10n.shrinkageArrived(
            shrinkage.received,
            shrinkage.totalBoxes,
          ),
        ),
        // The percentage is computed by the server and shown here without
        // adjectives: how much shrinkage is too much is coordination's
        // judgement.
        RecordField(
          label: context.l10n.shrinkageLabel,
          value:
              '${shrinkage.shrinkagePct}% · '
              '${context.l10n.boxCount(shrinkage.notReceived)}',
        ),
        // What the reception found is answered with an incident, and it is
        // raised from here and not from the button below: this is the place
        // where somebody discovers it.
        if (shrinkage.notReceived > 0)
          Consumer(
            builder: (context, ref, _) => ListTile(
              dense: true,
              leading: const Icon(Icons.report_outlined),
              title: Text(context.l10n.receptionRaiseIncident),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  reportShipmentIncident(context, ref, reception.shipmentId),
            ),
          ),
        // The campaign's shrinkage is looked at from here, which is where
        // somebody has just discovered that something does not add up.
        if (campaignId case final campaign?)
          ListTile(
            dense: true,
            leading: const Icon(Icons.insights_outlined),
            title: Text(context.l10n.reportsShrinkageOfCampaign),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(ReportsView.route(campaignId: campaign)),
          ),
        if (reception.notes case final notes?)
          RecordField(label: context.l10n.receptionNotesLabel, value: notes),
      ],
    );
  }
}

class _Incident extends StatelessWidget {
  const _Incident({required this.incident});

  final IncidentOut incident;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(
      incident.resolvedAt == null
          ? Icons.error_outline
          : Icons.check_circle_outline,
    ),
    title: Text(incidentTypeLabel(context.l10n, incident.type)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(incident.description),
        if (incident.resolutionNote case final note?)
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '${incident.status} · ${formatShortDate(incident.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
    isThreeLine: true,
  );
}

/// One step of the journey. Milestones are read by their name; state changes,
/// as the transition they were. Recording milestones requires national
/// administration, so here they are only read.
class _Event extends StatelessWidget {
  const _Event({required this.event});

  final QrEventOut event;

  @override
  Widget build(BuildContext context) {
    final described = describeEvent(
      context.l10n,
      event,
      statusLabel: (status) => shipmentStatusLabel(context.l10n, status),
    );

    return ListTile(
      dense: true,
      leading: Icon(
        event.milestone != null ? Icons.flag_outlined : Icons.arrow_forward,
      ),
      title: Text(described.title),
      subtitle: Text(
        [formatShortDate(described.at), ?described.note].join(' · '),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}
