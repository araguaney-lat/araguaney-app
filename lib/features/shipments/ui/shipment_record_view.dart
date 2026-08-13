import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/api/generated/models/reception_out.dart';
import '../../../core/api/generated/models/shipment_detail_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/ui/record_field.dart';
import '../../incidents/data/incidents_providers.dart';
import '../../incidents/data/incidents_repository.dart';
import '../../incidents/ui/report_incident_sheet.dart';
import '../data/shipments_providers.dart';
import '../data/shipments_repository.dart';

/// Ficha de un envío, de solo lectura, con lo que llegó y lo que no.
///
/// Llegó antes que el resto de la fase 10 porque un aviso de entrega necesitaba
/// dónde aterrizar. Ahora cuenta la historia completa desde el lado del centro
/// que envió: la recepción dice qué llegó bien, las incidencias qué no, y
/// levantar una es lo único que se escribe desde aquí.
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

  Future<void> _report(BuildContext context, WidgetRef ref) async {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.operatorMessage)));
    }
  }

  /// Pide el manifiesto y lo abre.
  ///
  /// El servidor no devuelve el PDF: devuelve un trabajo, y el documento llega
  /// cuando termina de armarse. Si tarda más de lo que este sondeo espera, se
  /// dice — el trabajo sigue vivo allá y volver a pedirlo lo recoge.
  Future<void> _manifest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(
      context,
    )..showSnackBar(const SnackBar(content: Text('Preparando el manifiesto…')));

    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .manifest(shipmentId);
    if (!context.mounted) return;

    // El aviso de espera se retira antes de decir cómo terminó: si no, la
    // respuesta se encola detrás de él y llega cuando ya nadie mira.
    messenger.hideCurrentSnackBar();

    switch (outcome) {
      case ManifestReady(:final downloadUrl):
        final opened = await ref.read(openLinkProvider)(downloadUrl);
        if (!opened) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el manifiesto en este teléfono.'),
            ),
          );
        }
      case ManifestStillWorking():
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'El manifiesto sigue armándose. Vuelve a pedirlo en un momento.',
            ),
          ),
        );
      case ManifestFailed(:final message):
        messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipment = ref.watch(shipmentProvider(shipmentId));
    final canReport = ref.watch(isCenterCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(shipment.valueOrNull?.reference ?? 'Envío'),
        actions: [
          IconButton(
            tooltip: 'Manifiesto',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => _manifest(context, ref),
          ),
        ],
      ),
      floatingActionButton: canReport
          ? FloatingActionButton.extended(
              onPressed: () => _report(context, ref),
              icon: const Icon(Icons.report_outlined),
              label: const Text('Incidencia'),
            )
          : null,
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
              ApiErrorMapper.fromAny(error).operatorMessage,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reception = ref.watch(shipmentReceptionProvider(shipmentId));
    final incidents = ref.watch(shipmentIncidentsProvider(shipmentId));
    final events = ref.watch(shipmentEventsProvider(shipmentId));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        RecordField(label: 'Estado', value: shipment.status),
        RecordField(label: 'Destino', value: shipment.destination),
        if (shipment.carrier case final carrier?)
          RecordField(label: 'Transportista', value: carrier),
        RecordField(label: 'Tarimas', value: '${shipment.pallets.length}'),
        if (shipment.shippedAt case final shipped?)
          RecordField(label: 'Despachado', value: formatShortDate(shipped)),
        if (shipment.deliveredAt case final delivered?)
          RecordField(label: 'Entregado', value: formatShortDate(delivered)),
        if (shipment.notes case final notes?)
          RecordField(label: 'Notas', value: notes),
        const Divider(),
        _SectionTitle('Recepción'),
        switch (reception) {
          AsyncData(value: final value?) => _Reception(reception: value),
          AsyncData() => const _Note(
            'Todavía no se registró la recepción de este envío.',
          ),
          AsyncError() => const _Note('No se pudo consultar la recepción.'),
          _ => const _Note('Consultando…'),
        },
        const Divider(),
        _SectionTitle('Recorrido'),
        switch (events) {
          AsyncData(:final value) when value.isEmpty => const _Note(
            'Todavía no hay hitos anotados para este envío.',
          ),
          AsyncData(:final value) => Column(
            children: [for (final event in value) _Event(event: event)],
          ),
          AsyncError() => const _Note('No se pudo consultar el recorrido.'),
          _ => const _Note('Consultando…'),
        },
        const Divider(),
        _SectionTitle('Incidencias'),
        switch (incidents) {
          AsyncData(:final value) when value.isEmpty => const _Note(
            'Ninguna incidencia levantada sobre este envío.',
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final incident in value) _Incident(incident: incident),
            ],
          ),
          AsyncError() => const _Note('No se pudieron consultar.'),
          _ => const _Note('Consultando…'),
        },
        const SizedBox(height: 80),
      ],
    );
  }
}

class _Reception extends StatelessWidget {
  const _Reception({required this.reception});

  final ReceptionOut reception;

  @override
  Widget build(BuildContext context) {
    final shrinkage = reception.shrinkage;

    return Column(
      children: [
        RecordField(
          label: 'Recibida',
          value: formatShortDate(reception.receivedAt),
        ),
        if (reception.consigneeName case final consignee?)
          RecordField(label: 'Recibió', value: consignee),
        RecordField(
          label: 'Cajas',
          value:
              '${shrinkage.received} de ${shrinkage.totalBoxes} llegaron bien',
        ),
        // El porcentaje lo calcula el servidor y aquí se enseña sin adjetivos:
        // cuánta merma es demasiada es un criterio de la coordinación.
        RecordField(
          label: 'Merma',
          value: '${shrinkage.shrinkagePct}% · ${shrinkage.notReceived} cajas',
        ),
        if (reception.notes case final notes?)
          RecordField(label: 'Notas de la recepción', value: notes),
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
    title: Text(incidentTypeLabel(incident.type)),
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

/// Un paso del recorrido. Los hitos se leen con su nombre; los cambios de
/// estado, como la transición que fueron. Anotar hitos exige administración
/// nacional, así que aquí solo se leen.
class _Event extends StatelessWidget {
  const _Event({required this.event});

  final QrEventOut event;

  @override
  Widget build(BuildContext context) {
    final described = describeShipmentEvent(event);

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
