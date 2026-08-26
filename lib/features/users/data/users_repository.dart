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

/// Las personas de la plataforma, más allá de un centro.
///
/// El directorio de equipo cubre un centro y lo llama por su ruta propia; esto
/// es la otra mitad, la que cruza centros. Las dos existen porque el servidor
/// las separa: `/v1/centers/{id}/users` la mira una coordinación, y
/// `/v1/studio/users` exige `require_user_manager`.
///
/// **`require_user_manager` no es `superadmin`.** Es una puerta más ancha —la
/// plataforma o la operación nacional— y por eso esto es administración y no
/// consola, aunque las rutas compartan el prefijo `studio`.
///
/// `PATCH /v1/studio/users/{id}` existe y **aquí no está**: cambiar el rol o el
/// centro de alguien tiene consecuencias que duran más que el momento, y
/// hacerlo desde un teléfono entre dos tarimas no es mejor que hacerlo desde un
/// escritorio. Se añadirá el día que haya un caso, no antes.
class UsersRepository {
  UsersRepository(this._studio);

  final StudioApi _studio;

  /// Una página de personas, con los filtros que el servidor entiende.
  ///
  /// **No hay búsqueda por texto**: el endpoint filtra por centro, rol y
  /// actividad, y pagina. Buscar «Ana» es cosa de la pantalla sobre lo que ya
  /// trajo, y por eso la pantalla dice que eso es lo que hace.
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

  /// Da de alta a alguien en cualquier centro.
  ///
  /// La contraseña no viaja: el servidor la genera y la manda por correo. Este
  /// cliente nunca la ve, que es la única forma de que no pueda filtrarla.
  Future<UsersOutcome<UserOut>> invite(StudioUserCreate data) =>
      _guard(() => _studio.createUserV1StudioUsersPost(body: data));

  /// Reenvía el acceso a quien nunca lo recibió.
  ///
  /// Es la operación de esta fase con un caso real lejos de un escritorio:
  /// alguien dice «no me llegó» delante de ti.
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
