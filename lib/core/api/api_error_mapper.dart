import 'package:dio/dio.dart';

import 'api_failure.dart';

/// Translates what dio throws into the backend's error envelope.
///
/// It lives apart from [ApiFailure] on purpose: the failure types must not
/// depend on the HTTP library. If dio is swapped out tomorrow, this file gets
/// rewritten and nothing else.
abstract final class ApiErrorMapper {
  /// Statuses the backend uses to say "this is not a technical failure, it is
  /// a business rule". Their message is shown to whoever is operating.
  static const _businessStatuses = {400, 409, 422};

  static ApiFailure fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure(message: error.message ?? 'No connection');
      case DioExceptionType.cancel:
        return const UnknownFailure(
          code: 'CANCELLED',
          message: 'The request was cancelled',
        );
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          code: 'BAD_CERTIFICATE',
          message: 'Invalid server certificate',
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

  /// Translates anything that was caught.
  ///
  /// It exists because a broad `catch` receives `Object`, and whoever writes it
  /// should not have to tell an already-translated failure, a dio one and a
  /// programming error apart by hand.
  static ApiFailure fromAny(Object error) => switch (error) {
    ApiFailure() => error,
    DioException() => fromDioException(error),
    _ => UnknownFailure(code: 'UNEXPECTED', message: error.toString()),
  };

  /// Reads the body of an error response.
  ///
  /// A healthy backend sends `{"error": {...}}`, but this layer also has to
  /// survive whatever sits in the way: a Cloudflare error page, a proxy that
  /// answers plain text, or an empty body. So nothing here assumes the body's
  /// shape, and the HTTP status decides when the body says nothing.
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

  /// A mirror of the backend's status map, so a missing body does not leave the
  /// code blank.
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
