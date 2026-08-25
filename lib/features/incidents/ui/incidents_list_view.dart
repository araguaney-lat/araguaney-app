import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/ui/relative_time.dart';
import '../../../core/ui/status_labels.dart';
import '../../shipments/ui/shipment_record_view.dart';
import '../data/incidents_providers.dart';
import '../data/incidents_repository.dart';
import 'resolve_incident_sheet.dart';

/// Las incidencias del centro.
///
/// **Cierra media función que llevaba meses publicada.** La aplicación sabía
/// levantar una incidencia desde un envío y no sabía enseñarla, que es la peor
/// mitad para que falte: alguien reporta que falta una caja y no tiene forma de
/// saber si alguien la miró.
///
/// Abiertas primero y por edad, porque una incidencia vieja y abierta es
/// exactamente la que se está olvidando. Cerrarla exige administración
/// nacional; listarlas, solo coordinación.
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
          const SnackBar(content: Text('La incidencia quedó cerrada.')),
        );
      case IncidentsRefused(:final failure):
        messenger.showSnackBar(
          SnackBar(content: Text(failure.operatorMessage)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidents = ref.watch(centerIncidentsProvider);
    final canResolve = ref.watch(canResolveIncidentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incidencias')),
      body: switch (incidents) {
        AsyncData(value: IncidentsRead(:final value)) when value.isEmpty =>
          const _Message('No hay incidencias registradas.'),
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
                ? 'Hace falta coordinar un centro para ver sus incidencias.'
                : failure.operatorMessage,
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
    // Abiertas primero, y dentro de cada grupo la más vieja arriba: una
    // incidencia vieja y abierta es la que se está olvidando.
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Ya cerradas'),
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
    child: Text(switch (open) {
      0 => 'Ninguna espera una decisión',
      1 => 'Una incidencia abierta',
      _ => '$open incidencias abiertas',
    }, style: Theme.of(context).textTheme.bodyMedium),
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
                    incidentTypeLabel(incident.type),
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  describeAge(incident.createdAt, DateTime.now()),
                  style: text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Citada: son las palabras de quien la reportó.
            Text('«${incident.description}»', style: text.bodyMedium),
            if (incident.resolutionNote case final note? when note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Cerrada: $note', style: text.bodySmall),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(label: Text(incidentStatusLabel(incident.status))),
                const Spacer(),
                // El envío al que pertenece: es donde se puede mirar qué pasó.
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(ShipmentRecordView.route(incident.shipmentId)),
                  child: const Text('Ver envío'),
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
                        child: const Text('Cerrar'),
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
