import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
import 'users_repository.dart';

final usersRepositoryProvider = Provider<UsersRepository>(
  (ref) => UsersRepository(ref.watch(restClientProvider).studio),
);

/// Whether this session administers people beyond its own centre.
///
/// It copies `require_user_manager`, which is wider than the console: the
/// platform **or** the national operation. A centre invites its own people
/// through another route, and that has worked since phase 14.
final canManageUsersProvider = Provider<bool>((ref) {
  if (ref.watch(isNationalAdminProvider)) return true;
  final state = ref.watch(sessionControllerProvider);
  return state is SessionActive && state.session.role == 'superadmin';
});

/// What is asked of the server: what it knows how to filter by.
typedef UserFilter = ({String? centerId, String? centerRole, bool? isActive});

/// One page of people.
///
/// The scrolling lives in the screen and not here: asking for the next page is
/// a gesture of whoever is looking, not a state of the repository.
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
