import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/api/generated/models/shipment_out.dart';
import '../../../core/center/center_providers.dart';
import 'shipments_repository.dart';

final shipmentsRepositoryProvider = Provider<ShipmentsRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return ShipmentsRepository(
    shipments: client.shipments,
    exports: client.exports,
  );
});

/// The centre's shipments. They are looked up online: coordinating a shipment
/// requires signal anyway, and a cached listing would show as open one that
/// somebody else has already dispatched.
/// Narrowed to the working centre, by the same rule as the pallets: what leaves
/// this warehouse is what somebody standing in it can act on.
final shipmentsProvider = FutureProvider<List<ShipmentOut>>((ref) async {
  final shipments = await ref.watch(shipmentsRepositoryProvider).list();
  final center = ref.watch(writeCenterIdProvider);
  if (center == null) return shipments;
  return shipments
      .where((shipment) => shipment.centerId == center)
      .toList(growable: false);
});

/// The shipment's journey: state changes and logistical milestones.
final shipmentEventsProvider = FutureProvider.family<List<QrEventOut>, String>(
  (ref, shipmentId) =>
      ref.watch(shipmentsRepositoryProvider).events(shipmentId),
);
