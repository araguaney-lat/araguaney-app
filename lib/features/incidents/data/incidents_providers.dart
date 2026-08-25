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

/// La recepción de un envío. Nulo mientras no se haya reconciliado.
final shipmentReceptionProvider = FutureProvider.family<ReceptionOut?, String>(
  (ref, shipmentId) =>
      ref.watch(incidentsRepositoryProvider).reception(shipmentId),
);

/// Las incidencias del centro, sin envío de por medio.
final centerIncidentsRepositoryProvider = Provider<CenterIncidentsRepository>(
  (ref) => CenterIncidentsRepository(ref.watch(restClientProvider).incidents),
);

/// Todo lo que hay, abierto y cerrado. El servidor acepta filtrar por estado,
/// pero pedir las dos cosas de una permite mostrar el conteo de lo abierto sin
/// una segunda petición.
final centerIncidentsProvider =
    FutureProvider<IncidentsOutcome<List<IncidentOut>>>(
      (ref) => ref.watch(centerIncidentsRepositoryProvider).list(),
    );

/// Si esta sesión puede cerrar una. El backend exige administración nacional
/// en el cierre, aunque listar solo pida coordinación.
final canResolveIncidentsProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);
