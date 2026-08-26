import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/studio_api.dart';
import '../../../core/api/generated/models/studio_user_create.dart';
import '../../../core/api/generated/models/user_out.dart';

sealed class UsersOutcome<T> {
  const UsersOutcome();
}

final class UsersRead<T> extends UsersOutcome<T> {
  const UsersRead(this.value);

  final T value;
}

final class UsersRefused<T> extends UsersOutcome<T> {
  const UsersRefused(this.failure);

  final ApiFailure failure;

  bool get isForbidden => failure is ForbiddenFailure;
}

/// The platform's people, beyond one centre.
///
/// The team directory covers one centre and calls it by its own route; this is
/// the other half, the one that crosses centres. Both exist because the server
/// separates them: `/v1/centers/{id}/users` is looked at by a coordination, and
/// `/v1/studio/users` requires `require_user_manager`.
///
/// **`require_user_manager` is not `superadmin`.** It is a wider door — the
/// platform or the national operation — and that is why this is administration
/// and not the console, even though the routes share the `studio` prefix.
///
/// `PATCH /v1/studio/users/{id}` exists and **is not here**: changing somebody's
/// role or centre has consequences that outlast the moment, and doing it from a
/// phone between two pallets is no better than doing it from a desk. It will be
/// added the day there is a case, not before.
class UsersRepository {
  UsersRepository(this._studio);

  final StudioApi _studio;

  /// One page of people, with the filters the server understands.
  ///
  /// **There is no text search**: the endpoint filters by centre, role and
  /// activity, and paginates. Looking for «Ana» is the screen's business over
  /// what it already brought, and that is why the screen says that is what it
  /// does.
  Future<UsersOutcome<List<UserOut>>> list({
    String? centerId,
    String? centerRole,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) => _guard(
    () => _studio.listUsersV1StudioUsersGet(
      centerId: centerId,
      centerRole: centerRole,
      isActive: isActive,
      limit: limit,
      offset: offset,
    ),
  );

  /// Adds somebody at any centre.
  ///
  /// The password does not travel: the server generates it and sends it by
  /// email. This client never sees it, which is the only way it cannot leak it.
  Future<UsersOutcome<UserOut>> invite(StudioUserCreate data) =>
      _guard(() => _studio.createUserV1StudioUsersPost(body: data));

  /// Resends the access to somebody who never received it.
  ///
  /// It is this phase's operation with a real case far from a desk: somebody
  /// says «it did not arrive» right in front of you.
  Future<UsersOutcome<void>> resendAccess(String userId) => _guard(
    () => _studio.reinviteUserV1StudioUsersUserIdReinvitePost(userId: userId),
  );

  Future<UsersOutcome<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return UsersRead(await call());
    } on Object catch (error) {
      return UsersRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
