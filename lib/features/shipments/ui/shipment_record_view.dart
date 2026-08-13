import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/shipment_detail_out.dart';
import '../../../core/ui/record_field.dart';

/// Ficha de un envío, de solo lectura.
///
/// Llega antes que el resto de la fase 10 por una razón concreta: un aviso de
/// entrega necesita dónde aterrizar, y un aviso sin destino es peor que no
/// tener aviso. Los hitos logísticos y el manifiesto siguen siendo trabajo de
/// esa fase.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipment = ref.watch(shipmentProvider(shipmentId));

    return Scaffold(
      appBar: AppBar(title: Text(shipment.valueOrNull?.reference ?? 'Envío')),
      body: switch (shipment) {
        AsyncData(:final value) => _Fields(shipment: value),
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

class _Fields extends StatelessWidget {
  const _Fields({required this.shipment});

  final ShipmentDetailOut shipment;

  @override
  Widget build(BuildContext context) => ListView(
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
    ],
  );
}
