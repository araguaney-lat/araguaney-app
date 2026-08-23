import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/api/generated/models/shipment_out.dart';
import 'shipments_repository.dart';

final shipmentsRepositoryProvider = Provider<ShipmentsRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return ShipmentsRepository(
    shipments: client.shipments,
    exports: client.exports,
  );
});

/// Los envíos del centro. Se consultan en línea: coordinar un envío exige
/// señal de todos modos, y un listado cacheado enseñaría como abierto uno que
/// otra persona ya despachó.
final shipmentsProvider = FutureProvider<List<ShipmentOut>>(
  (ref) => ref.watch(shipmentsRepositoryProvider).list(),
);

/// El recorrido del envío: cambios de estado y hitos logísticos.
final shipmentEventsProvider = FutureProvider.family<List<QrEventOut>, String>(
  (ref, shipmentId) =>
      ref.watch(shipmentsRepositoryProvider).events(shipmentId),
);
