import 'package:araguaney_app/core/api/api_error_mapper.dart';
import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/l10n.dart';

DioException _badResponse(int status, Object? body) => DioException(
  requestOptions: RequestOptions(path: '/v1/intakes'),
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: RequestOptions(path: '/v1/intakes'),
    statusCode: status,
    data: body,
  ),
);

Map<String, dynamic> _envelope(
  String code,
  String message, {
  String? field,
  Map<String, dynamic>? meta,
}) => {
  'error': {'code': code, 'message': message, 'field': field, 'meta': meta},
};

void main() {
  group('envelope parsing', () {
    test(
      'reads code, message, field and meta from the error envelope',
      () async {
        final failure = ApiErrorMapper.fromDioException(
          _badResponse(
            409,
            _envelope(
              'CODE_ALREADY_USED',
              'El código ya fue usado',
              field: 'code',
              meta: {'box_id': 'abc'},
            ),
          ),
        );

        expect(failure, isA<BusinessRuleFailure>());
        expect(failure.code, 'CODE_ALREADY_USED');
        expect(failure.field, 'code');
        expect(failure.meta, {'box_id': 'abc'});
      },
    );

    test(
      'falls back to the status code when the body carries no envelope',
      () async {
        // A proxy's error page does not carry the backend's envelope; the
        // mapping cannot depend on the body having the expected shape.
        final failure = ApiErrorMapper.fromDioException(
          _badResponse(503, '<html>Service Unavailable</html>'),
        );

        expect(failure, isA<ServerFailure>());
        expect(failure.code, 'SERVICE_UNAVAILABLE');
      },
    );

    test('survives a null body', () async {
      final failure = ApiErrorMapper.fromDioException(_badResponse(404, null));

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, 'NOT_FOUND');
    });
  });

  group('status to failure type', () {
    final cases = <int, Type>{
      400: BusinessRuleFailure,
      401: UnauthorizedFailure,
      403: ForbiddenFailure,
      404: NotFoundFailure,
      409: BusinessRuleFailure,
      422: BusinessRuleFailure,
      429: RateLimitFailure,
      500: ServerFailure,
      502: ServerFailure,
    };

    cases.forEach((status, expectedType) {
      test('$status maps to $expectedType', () async {
        final failure = ApiErrorMapper.fromDioException(
          _badResponse(status, _envelope('ANY', 'mensaje')),
        );
        expect(failure.runtimeType, expectedType);
      });
    });
  });

  group('transport errors', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.connectionError,
    ]) {
      test('$type becomes a retryable network failure', () async {
        final failure = ApiErrorMapper.fromDioException(
          DioException(
            requestOptions: RequestOptions(path: '/v1/intakes'),
            type: type,
          ),
        );

        expect(failure, isA<NetworkFailure>());
        expect(failure.isRetryable, isTrue);
      });
    }
  });

  group('retry policy', () {
    test('business rejections are not retryable', () async {
      // The offline capture queue depends on this distinction: retrying a
      // business refusal would give the same answer forever.
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(422, _envelope('EXPIRY_TOO_SOON', 'Vida útil corta')),
      );

      expect(failure.isRetryable, isFalse);
    });

    test('server and rate-limit failures are retryable', () async {
      for (final status in [429, 500, 503]) {
        final failure = ApiErrorMapper.fromDioException(
          _badResponse(status, _envelope('X', 'y')),
        );
        expect(failure.isRetryable, isTrue, reason: 'status $status');
      }
    });
  });

  group('operator-facing messages', () {
    test('a business rule shows the server message verbatim', () async {
      final failure = ApiErrorMapper.fromDioException(
        _badResponse(
          422,
          _envelope('EXPIRY_TOO_SOON', 'La caducidad es menor a 365 días'),
        ),
      );

      expect(
        failure.operatorMessage(await spanish()),
        'La caducidad es menor a 365 días',
      );
    });

    test(
      'a technical failure shows generic copy, not the server message',
      () async {
        final failure = ApiErrorMapper.fromDioException(
          _badResponse(
            500,
            _envelope('INTERNAL_ERROR', 'psycopg2.OperationalError'),
          ),
        );

        expect(
          failure.operatorMessage(await spanish()),
          isNot(contains('psycopg2')),
        );
        expect(failure.message, 'psycopg2.OperationalError');
      },
    );
  });
}
