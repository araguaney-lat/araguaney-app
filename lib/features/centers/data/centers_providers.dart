import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/center_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'centers_repository.dart';

final centersRepositoryProvider = Provider<CentersRepository>(
  (ref) => CentersRepository(ref.watch(restClientProvider).centers),
);

/// Los centros, para quien puede listarlos.
///
/// Se pide una vez y se reutiliza: es una lista corta que cambia poco, y quien
/// la mira suele estar resolviendo varios identificadores seguidos —las filas
/// de una lista de transferencias, por ejemplo.
final centersProvider = FutureProvider<CentersOutcome<List<CenterOut>>>(
  (ref) => ref.watch(centersRepositoryProvider).list(),
);

/// Nombres de centro por identificador, o vacío si esta sesión no puede
/// resolverlos.
///
/// **Vacío no es un error.** Listar centros exige administración nacional, así
/// que para una coordinación esto siempre estará vacío y la interfaz tiene que
/// comportarse igual que antes: sin nombre, sin hueco y sin disculpa. Es lo que
/// la petición 3 pide arreglar de verdad, añadiendo los nombres al contrato de
/// la transferencia; esto solo deja de callar para quien sí puede mirarlos.
final centerNamesProvider = Provider<Map<String, String>>((ref) {
  final centers = ref.watch(centersProvider).valueOrNull;
  return switch (centers) {
    CentersRead(:final value) => {
      for (final center in value) center.id: center.name,
    },
    _ => const {},
  };
});

/// Si esta sesión puede pedir la lista. El backend exige administración
/// nacional en los dos endpoints de centros.
final canListCentersProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);

/// La ficha de un centro concreto.
final centerRecordProvider =
    FutureProvider.family<CentersOutcome<CenterOut>, String>(
      (ref, id) => ref.watch(centersRepositoryProvider).byId(id),
    );
