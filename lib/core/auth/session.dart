import '../api/generated/models/token.dart';

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
    required this.centerId,
    required this.centerRole,
    required this.mustChangePassword,
    required this.mustAcceptTerms,
  });

  factory Session.fromToken(Token token) => Session(
    accessToken: token.accessToken,
    refreshToken: token.refreshToken,
    role: token.role,
    centerId: token.centerId,
    centerRole: token.centerRole,
    mustChangePassword: token.mustChangePassword,
    mustAcceptTerms: token.mustAcceptTerms,
  );

  final String accessToken;
  final String? refreshToken;

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

/// No hay sesión. [failureMessage] explica por qué, cuando la hay.
class SessionAbsent extends SessionState {
  const SessionAbsent({this.failureMessage});

  final String? failureMessage;
}

/// Credenciales correctas, falta el segundo factor.
///
/// El token parcial vive solo en memoria y caduca en minutos: no es una sesión
/// y no se persiste.
class SessionAwaitingTotp extends SessionState {
  const SessionAwaitingTotp({required this.partialToken, this.failureMessage});

  final String partialToken;
  final String? failureMessage;
}

/// Hay sesión. Si [Session.mustChangePassword] es cierto, la interfaz interpone
/// el cambio de contraseña antes de dejar operar.
class SessionActive extends SessionState {
  const SessionActive(this.session);

  final Session session;
}
