import '../api/api_failure.dart';

import '../api/generated/models/token.dart';
import '../api/generated/models/user_out.dart';

/// Sesión activa de una persona operadora.
///
/// Es inmutable: renovar el token produce una sesión nueva, nunca modifica la
/// existente. Así, quien esté leyendo la sesión durante una renovación no ve un
/// estado a medias.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userId,
    required this.centerId,
    required this.centerRole,
    required this.mustChangePassword,
    required this.mustAcceptTerms,
  });

  /// El token no lleva identidad, así que [userId] se resuelve aparte y se
  /// inyecta aquí. Es nulo cuando no se pudo confirmar quién es.
  ///
  /// Los datos de identidad se toman del token, y de [identity] cuando el
  /// token no los trae.
  ///
  /// `POST /v1/auth/refresh` devuelve solo los tokens: ni rol de centro ni
  /// centro. Como restaurar la sesión al abrir la aplicación pasa por ahí, sin
  /// este relleno quien coordina un centro reaparecía como voluntariado en cada
  /// reinicio —sin su rol, sin sus acciones— hasta volver a iniciar sesión.
  factory Session.fromToken(Token token, {String? userId, UserOut? identity}) =>
      Session(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        role: token.role ?? identity?.role,
        userId: userId,
        centerId: token.centerId ?? identity?.centerId,
        centerRole: token.centerRole ?? identity?.centerRole,
        mustChangePassword: token.mustChangePassword,
        mustAcceptTerms: token.mustAcceptTerms,
      );

  final String accessToken;
  final String? refreshToken;

  /// Quién abrió la sesión. Es la clave del alcance del cache y, en la fase
  /// siguiente, de la cola de captura.
  final String? userId;

  /// Rol de plataforma del boilerplate: `user`, `admin` o `superadmin`.
  final String? role;

  /// Centro al que pertenece. Nulo en una administración nacional, que ve todo.
  final String? centerId;

  /// Rol de dominio: `volunteer`, `coordinator` o `national_admin`.
  final String? centerRole;

  /// El servidor exige cambiar la contraseña antes de operar.
  final bool mustChangePassword;

  /// El servidor pide aceptar los términos. No bloquea operaciones en el
  /// backend, así que aquí se conserva como dato y no como puerta.
  final bool mustAcceptTerms;

  /// La cola de captura sin conexión es por usuario, y en un dispositivo
  /// compartido el centro es parte de esa identidad.
  Session copyWith({String? accessToken, String? refreshToken}) => Session(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    role: role,
    userId: userId,
    centerId: centerId,
    centerRole: centerRole,
    mustChangePassword: mustChangePassword,
    mustAcceptTerms: mustAcceptTerms,
  );
}

/// Estado de la sesión en el dispositivo.
sealed class SessionState {
  const SessionState();
}

/// Todavía no se sabe: se está leyendo el almacén seguro al arrancar.
class SessionRestoring extends SessionState {
  const SessionRestoring();
}

/// No hay sesión. [failure] explica por qué, cuando hay un porqué.
///
/// Lleva el fallo y no una frase: redactar aquí obligaría a que el controlador
/// —que no tiene contexto— eligiera un idioma, y esta aplicación va a tener
/// varios. La pantalla, que sí lo tiene, la redacta con
/// `loginFailureMessage`.
class SessionAbsent extends SessionState {
  const SessionAbsent({this.failure});

  final ApiFailure? failure;
}

/// Credenciales correctas, falta el segundo factor.
///
/// El token parcial vive solo en memoria y caduca en minutos: no es una sesión
/// y no se persiste.
class SessionAwaitingTotp extends SessionState {
  const SessionAwaitingTotp({required this.partialToken, this.failure});

  final String partialToken;
  final ApiFailure? failure;
}

/// Hay sesión. Si [Session.mustChangePassword] es cierto, la interfaz interpone
/// el cambio de contraseña antes de dejar operar.
class SessionActive extends SessionState {
  const SessionActive(this.session);

  final Session session;
}
