import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import 'users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(restClientProvider).studio),
);

/// Si esta sesión administra personas más allá de su centro.
///
/// Copia `require_user_manager`, que es más ancha que la consola: la plataforma
/// **o** la operación nacional. Un centro invita a su propia gente por otra
/// ruta, y eso ya funciona desde la fase 14.
final canManageUsersProvider = Provider<bool>((ref) {
  if (ref.watch(isNationalAdminProvider)) return true;
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive && state.session.role == 'superadmin';
});

/// Qué se le pide al servidor: lo que él sabe filtrar.
typedef UserFilter = ({String? centerId, String? centerRole, bool? isActive});

/// Una página de personas.
///
/// El desplazamiento vive en la pantalla y no aquí: pedir la siguiente página
/// es un gesto de quien mira, no un estado del repositorio.
final usersPageProvider =
    FutureProvider.family<UsersOutcome<List<UserOut>>, UserFilter>(
      (ref, filter) => ref
          .watch(usersRepositoryProvider)
          .list(
            centerId: filter.centerId,
            centerRole: filter.centerRole,
            isActive: filter.isActive,
          ),
    );
