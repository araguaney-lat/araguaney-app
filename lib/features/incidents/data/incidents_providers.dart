import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/incident_out.dart';
import '../../../core/api/generated/models/reception_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'incidents_repository.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>(
  (ref) => IncidentsRepository(ref.watch(restClientProvider).shipments),
);

final shipmentIncidentsProvider =
    FutureProvider.family<List<IncidentOut>, String>(
      (ref, shipmentId) =>
          ref.watch(incidentsRepositoryProvider).forShipment(shipmentId),
    );

/// A shipment's reception. Null while it has not been reconciled.
final shipmentReceptionProvider = FutureProvider.family<ReceptionOut?, String>(
  (ref, shipmentId) =>
      ref.watch(incidentsRepositoryProvider).reception(shipmentId),
);

/// The centre's incidents, with no shipment in between.
final centerIncidentsRepositoryProvider = Provider<CenterIncidentsRepository>(
  (ref) => CenterIncidentsRepository(ref.watch(restClientProvider).incidents),
);

/// Everything there is, open and closed. The server accepts filtering by state,
/// but asking for both at once allows showing the count of what is open without
/// a second request.
final centerIncidentsProvider =
    FutureProvider<IncidentsOutcome<List<IncidentOut>>>(
      (ref) => ref.watch(centerIncidentsRepositoryProvider).list(),
    );

/// Whether this session can close one. The backend requires national
/// administration to close, even though listing only asks for coordination.
final canResolveIncidentsProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);
