import 'package:dio/dio.dart';

import 'api_failure.dart';

/// Traduce lo que lanza dio al sobre de error del backend.
///
/// Vive aparte de [ApiFailure] a propósito: los tipos de fallo no deben
/// depender de la librería HTTP. Si mañana se cambia dio, se reescribe este
/// archivo y nada más.
abstract final class ApiErrorMapper {
  /// Códigos que el backend usa para decir "esto no es un fallo técnico, es una
  /// regla de negocio". Su mensaje sí se le muestra a quien opera.
  static const _businessStatuses = {400, 409, 422};

  static ApiFailure fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(message: error.message ?? 'Sin conexión');
      case DioExceptionType.cancel:
        return const UnknownFailure(
          code: 'CANCELLED',
          message: 'La petición se canceló',
        );
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          code: 'BAD_CERTIFICATE',
          message: 'Certificado del servidor no válido',
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return fromResponse(
          error.response?.statusCode,
          error.response?.data,
          fallbackMessage: error.message,
        );
    }
  }

  /// Traduce cualquier cosa que se haya atrapado.
  ///
  /// Existe porque un `catch` amplio recibe `Object`, y quien lo escribe no
  /// debería tener que distinguir a mano entre un fallo ya traducido, uno de
  /// dio y un error de programación.
  static ApiFailure fromAny(Object error) => switch (error) {
    ApiFailure() => error,
    DioException() => fromDioException(error),
    _ => UnknownFailure(code: 'UNEXPECTED', message: error.toString()),
  };

  /// Interpreta el cuerpo de una respuesta de error.
  ///
  /// Un backend sano manda `{"error": {...}}`, pero esta capa también tiene que
  /// sobrevivir a lo que se cruza en el camino: una página de error de
  /// Cloudflare, un proxy que responde texto plano o un cuerpo vacío. Por eso
  /// nada aquí asume la forma del cuerpo, y el estado HTTP decide cuando el
  /// cuerpo no dice nada.
  static ApiFailure fromResponse(
    int? statusCode,
    Object? body, {
    String? fallbackMessage,
  }) {
    final envelope = _readEnvelope(body);
    final code = envelope?['code'] as String? ?? _defaultCode(statusCode);
    final message =
        envelope?['message'] as String? ??
        fallbackMessage ??
        'Error ${statusCode ?? 'desconocido'}';
    final field = envelope?['field'] as String?;
    final meta = envelope?['meta'] as Map<String, dynamic>?;

    return switch (statusCode) {
      401 => UnauthorizedFailure(
        code: code,
        message: message,
        field: field,
        meta: meta,
      ),
      403 => ForbiddenFailure(
        code: code,
        message: message,
        field: field,
        meta: meta,
      ),
      404 => NotFoundFailure(
        code: code,
        message: message,
        field: field,
        meta: meta,
      ),
      429 => RateLimitFailure(
        code: code,
        message: message,
        field: field,
        meta: meta,
      ),
      final int status when _businessStatuses.contains(status) =>
        BusinessRuleFailure(
          code: code,
          message: message,
          field: field,
          meta: meta,
        ),
      final int status when status >= 500 => ServerFailure(
        code: code,
        message: message,
        field: field,
        meta: meta,
      ),
      _ => UnknownFailure(
        code: code,
        message: message,
        field: field,
        meta: meta,
      ),
    };
  }

  static Map<String, dynamic>? _readEnvelope(Object? body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    return error.map((key, value) => MapEntry(key.toString(), value));
  }

  /// Espejo del mapa de estados del backend, para que un cuerpo ausente no deje
  /// el código en blanco.
  static String _defaultCode(int? statusCode) => switch (statusCode) {
    400 => 'BAD_REQUEST',
    401 => 'UNAUTHORIZED',
    403 => 'FORBIDDEN',
    404 => 'NOT_FOUND',
    405 => 'METHOD_NOT_ALLOWED',
    409 => 'CONFLICT',
    410 => 'GONE',
    422 => 'VALIDATION_ERROR',
    429 => 'RATE_LIMIT_EXCEEDED',
    500 => 'INTERNAL_ERROR',
    502 => 'UPSTREAM_ERROR',
    503 => 'SERVICE_UNAVAILABLE',
    _ => 'ERROR',
  };
}
