import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/relative_time.dart';
import '../../../core/ui/status_labels.dart';
import '../../shipments/ui/shipment_record_view.dart';
import '../data/incidents_providers.dart';
import '../data/incidents_repository.dart';
import 'resolve_incident_sheet.dart';

/// The centre's incidents.
///
/// **It closes half a feature that had been shipped for months.** The
/// application knew how to raise an incident from a shipment and did not know
/// how to show it, which is the worse half to be missing: somebody reports that
/// a box is missing and has no way of knowing whether anybody looked.
///
/// Open ones first and by age, because an old open incident is exactly the one
/// being forgotten. Closing one requires national administration; listing them,
/// only coordination.
class IncidentsListView extends ConsumerStatefulWidget {
  const IncidentsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const IncidentsListView());

  @override
  ConsumerState<IncidentsListView> createState() => _IncidentsListViewState();
}

class _IncidentsListViewState extends ConsumerState<IncidentsListView> {
  String? _resolving;

  Future<void> _resolve(IncidentOut incident) async {
    final note = await ResolveIncidentSheet.show(
      context,
      description: incident.description,
    );
    if (note == null) return;

    setState(() => _resolving = incident.id);
    final outcome = await ref
        .read(centerIncidentsRepositoryProvider)
        .resolve(incident.id, note);
    if (!mounted) return;
    setState(() => _resolving = null);

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case IncidentsRead():
        ref.invalidate(centerIncidentsProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.incidentClosed)),
        );
      case IncidentsRefused(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(centerIncidentsProvider);
    final canResolve = ref.watch(canResolveIncidentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.incidentsTitle)),
      body: switch (incidents) {
        AsyncData(value: IncidentsRead(:final value)) when value.isEmpty =>
          _Message(context.l10n.incidentsEmpty),
        AsyncData(value: IncidentsRead(:final value)) => _List(
          incidents: value,
          canResolve: canResolve,
          resolving: _resolving,
          onResolve: _resolve,
        ),
        AsyncData(
          value: IncidentsRefused(:final isForbidden, :final failure),
        ) =>
          _Message(
            isForbidden
                ? context.l10n.incidentsForbidden
                : failure.operatorMessage(context.l10n),
          ),
        AsyncError(:final error) => _Message('$error'),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _List extends ConsumerWidget {
  const _List({
    required this.incidents,
    required this.canResolve,
    required this.resolving,
    required this.onResolve,
  });

  final List<IncidentOut> incidents;
  final bool canResolve;
  final String? resolving;
  final void Function(IncidentOut) onResolve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Open ones first, and within each group the oldest at the top: an old open
    // incident is the one being forgotten.
    final open = incidents.where((i) => i.status == 'OPEN').toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final closed = incidents.where((i) => i.status != 'OPEN').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(centerIncidentsProvider),
      child: ListView(
        children: [
          _Header(open: open.length),
          for (final incident in open)
            _IncidentCard(
              incident: incident,
              canResolve: canResolve,
              busy: resolving == incident.id,
              onResolve: () => onResolve(incident),
            ),
          if (closed.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(context.l10n.incidentsClosedHeading),
            ),
            for (final incident in closed)
              _IncidentCard(
                incident: incident,
                canResolve: false,
                busy: false,
                onResolve: () {},
              ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.open});

  final int open;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      open == 0
          ? context.l10n.nothingAwaitsDecision
          : context.l10n.incidentsOpenCount(open),
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.canResolve,
    required this.busy,
    required this.onResolve,
  });

  final IncidentOut incident;
  final bool canResolve;
  final bool busy;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isOpen = incident.status == 'OPEN';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incidentTypeLabel(context.l10n, incident.type),
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  describeAge(context.l10n, incident.createdAt, DateTime.now()),
                  style: text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quoted: they are the words of whoever reported it.
            Text(
              context.l10n.quoted(incident.description),
              style: text.bodyMedium,
            ),
            if (incident.resolutionNote case final note? when note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.incidentClosedWithNote(note),
                  style: text.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(
                    incidentStatusLabel(context.l10n, incident.status),
                  ),
                ),
                const Spacer(),
                // The shipment it belongs to: it is where what happened can be
                // looked at.
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(ShipmentRecordView.route(incident.shipmentId)),
                  child: Text(context.l10n.incidentViewShipment),
                ),
              ],
            ),
            if (isOpen && canResolve)
              busy
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onResolve,
                        child: Text(context.l10n.actionClose),
                      ),
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
