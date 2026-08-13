import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/reception_out.dart';
import 'incidents_repository.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>(
  (ref) => IncidentsRepository(ref.watch(restClientProvider).shipments),
);

final shipmentIncidentsProvider =
    FutureProvider.family<List<IncidentOut>, String>(
      (ref, shipmentId) =>
          ref.watch(incidentsRepositoryProvider).forShipment(shipmentId),
    );

/// La recepción de un envío. Nulo mientras no se haya reconciliado.
final shipmentReceptionProvider = FutureProvider.family<ReceptionOut?, String>(
  (ref, shipmentId) =>
      ref.watch(incidentsRepositoryProvider).reception(shipmentId),
);
