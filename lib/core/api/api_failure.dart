/// Fallo de una llamada a la API, ya interpretado.
///
/// El backend responde los errores con un sobre estable
/// (`{"error": {"code", "message", "field", "meta"}}`). Esta capa lo traduce a
/// tipos que el resto de la aplicación puede distinguir sin volver a mirar
/// códigos HTTP sueltos.
///
/// Dos distinciones sostienen decisiones reales y por eso son parte del tipo,
/// no del sitio donde se atrapa el error:
///
/// - [isRetryable] separa lo transitorio (sin red, servidor caído) de lo que
///   va a responder igual por siempre (una regla de negocio). La cola de
///   captura sin conexión la necesita para no reintentar para siempre algo que
///   ya fue rechazado.
/// - [operatorMessage] decide qué se le enseña a quien opera. El mensaje del
///   servidor se muestra cuando describe una regla de negocio que esa persona
///   puede entender y corregir; un fallo técnico se muestra genérico y su
///   detalle queda para diagnóstico.
sealed class ApiFailure implements Exception {
  const ApiFailure({
    required this.code,
    required this.message,
    this.field,
    this.meta,
  });

  /// Código estable del backend (`VALIDATION_ERROR`, `CODE_ALREADY_USED`, …).
  final String code;

  /// Mensaje del servidor. No siempre es apto para mostrarse: ver
  /// [operatorMessage].
  final String message;

  /// Campo del formulario al que apunta el error, cuando el backend lo indica.
  final String? field;

  /// Datos adicionales del sobre de error.
  final Map<String, dynamic>? meta;

  /// Si reintentar la misma petición puede dar un resultado distinto.
  bool get isRetryable;

  /// Texto que se le muestra a quien opera.
  String get operatorMessage;

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// No se pudo hablar con el servidor: sin red, DNS, timeout o conexión cortada.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure({super.code = 'NETWORK_ERROR', required super.message});

  @override
  bool get isRetryable => true;

  @override
  String get operatorMessage =>
      'No hay conexión con el servidor. Revisa tu señal e inténtalo de nuevo.';
}

/// La sesión no es válida o expiró (401).
final class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String get operatorMessage => 'Tu sesión expiró. Inicia sesión de nuevo.';
}

/// La sesión es válida pero no alcanza para esta operación (403).
final class ForbiddenFailure extends ApiFailure {
  const ForbiddenFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String get operatorMessage => 'No tienes permiso para hacer esta operación.';
}

/// El recurso no existe o no es visible para este centro (404).
final class NotFoundFailure extends ApiFailure {
  const NotFoundFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String get operatorMessage => 'No encontramos lo que buscabas.';
}

/// El servidor rechazó la petición por una regla de negocio o de validación.
///
/// Es el único caso donde el mensaje del servidor se muestra tal cual: describe
/// algo que quien captura puede entender y corregir, como una caducidad corta o
/// un campo que falta. Traducirlo aquí sería mantener dos versiones de la misma
/// regla, y la del servidor es la que manda.
final class BusinessRuleFailure extends ApiFailure {
  const BusinessRuleFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String get operatorMessage => message;
}

/// Se superó el límite de peticiones (429).
final class RateLimitFailure extends ApiFailure {
  const RateLimitFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => true;

  @override
  String get operatorMessage =>
      'Demasiadas peticiones seguidas. Espera un momento e inténtalo de nuevo.';
}

/// El servidor falló (5xx).
final class ServerFailure extends ApiFailure {
  const ServerFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => true;

  @override
  String get operatorMessage =>
      'El servidor tuvo un problema. Inténtalo de nuevo en un momento.';
}

/// Cualquier otra cosa. Existe para que el mapeo sea total y nunca lance algo
/// que nadie haya previsto.
final class UnknownFailure extends ApiFailure {
  const UnknownFailure({
    required super.code,
    required super.message,
    super.field,
    super.meta,
  });

  @override
  bool get isRetryable => false;

  @override
  String get operatorMessage => 'Ocurrió un error inesperado.';
}
