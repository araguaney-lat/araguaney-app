import 'package:araguaney_app/core/auth/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

/// Mounts a client with the interceptor and a fake adapter.
///
/// The retry uses a separate client, as in the application: if it travelled
/// through the same one, a 401 during the renewal would fire another.
({Dio dio, FakeHttpAdapter adapter, FakeHttpAdapter retryAdapter})
_buildClient({
  required FakeResponse Function(RequestOptions) handler,
  required String? accessToken,
  required Future<String> Function() refreshSession,
  Future<void> Function()? onSessionExpired,
}) {
  final adapter = FakeHttpAdapter(handler);
  final retryAdapter = FakeHttpAdapter(handler);

  final retryClient = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = retryAdapter;

  var currentToken = accessToken;
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(
      AuthInterceptor(
        readAccessToken: () => currentToken,
        refreshSession: () async {
          final renewed = await refreshSession();
          currentToken = renewed;
          return renewed;
        },
        onSessionExpired: onSessionExpired ?? () async {},
        retryClient: retryClient,
      ),
    );

  return (dio: dio, adapter: adapter, retryAdapter: retryAdapter);
}

void main() {
  group('attaching the session', () {
    test('sends the access token on ordinary requests', () async {
      final client = _buildClient(
        handler: (_) => const FakeResponse(200, {'ok': true}),
        accessToken: 'access-1',
        refreshSession: () async => 'unused',
      );

      await client.dio.get<dynamic>('/v1/boxes');

      expect(
        client.adapter.requests.single.headers['Authorization'],
        'Bearer access-1',
      );
    });

    test('sends no session on the login endpoint', () async {
      // Sending an old credential while signing in adds nothing and leaks the
      // token of whoever used the device before.
      final client = _buildClient(
        handler: (_) => const FakeResponse(200, {'access_token': 'x'}),
        accessToken: 'stale-token',
        refreshSession: () async => 'unused',
      );

      await client.dio.post<dynamic>('/v1/auth/login');

      expect(
        client.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('adds no header when there is no session', () async {
      final client = _buildClient(
        handler: (_) => const FakeResponse(200, {'ok': true}),
        accessToken: null,
        refreshSession: () async => 'unused',
      );

      await client.dio.get<dynamic>('/v1/boxes');

      expect(
        client.adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('renewal on 401', () {
    test('renews and retries once, transparently to the caller', () async {
      var served = 0;
      var refreshes = 0;

      final client = _buildClient(
        handler: (options) {
          served++;
          // The first pass expires; after renewing, the resent request carries
          // the new token and goes through.
          return options.headers['Authorization'] == 'Bearer access-2'
              ? const FakeResponse(200, {'ok': true})
              : const FakeResponse(401, {
                  'error': {'code': 'UNAUTHORIZED', 'message': 'expirado'},
                });
        },
        accessToken: 'access-1',
        refreshSession: () async {
          refreshes++;
          return 'access-2';
        },
      );

      final response = await client.dio.get<dynamic>('/v1/boxes');

      expect(response.statusCode, 200);
      expect(refreshes, 1);
      expect(served, 2, reason: 'una original y un único reintento');
    });

    test('renews only once for requests that expire together', () async {
      // Opening a screen fires several requests together. Since the backend
      // rotates the refresh on every use, a second renewal would arrive with an
      // already revoked token and the server would read it as reuse.
      var refreshes = 0;

      final client = _buildClient(
        handler: (options) =>
            options.headers['Authorization'] == 'Bearer access-2'
            ? const FakeResponse(200, {'ok': true})
            : const FakeResponse(401, {
                'error': {'code': 'UNAUTHORIZED', 'message': 'expirado'},
              }),
        accessToken: 'access-1',
        refreshSession: () async {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'access-2';
        },
      );

      final responses = await Future.wait([
        client.dio.get<dynamic>('/v1/boxes'),
        client.dio.get<dynamic>('/v1/pallets'),
        client.dio.get<dynamic>('/v1/campaigns'),
      ]);

      expect(responses.every((r) => r.statusCode == 200), isTrue);
      expect(refreshes, 1);
    });

    test('does not renew again after a renewal already happened', () async {
      // If a 401 comes back after renewing, the token is not the problem.
      var refreshes = 0;

      final client = _buildClient(
        handler: (_) => const FakeResponse(401, {
          'error': {'code': 'UNAUTHORIZED', 'message': 'no'},
        }),
        accessToken: 'access-1',
        refreshSession: () async {
          refreshes++;
          return 'access-2';
        },
      );

      await expectLater(
        client.dio.get<dynamic>('/v1/boxes'),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 1);
    });

    test('does not try to renew a 401 from the refresh endpoint', () async {
      var refreshes = 0;

      final client = _buildClient(
        handler: (_) => const FakeResponse(401, {
          'error': {'code': 'INVALID_REFRESH', 'message': 'revocado'},
        }),
        accessToken: 'access-1',
        refreshSession: () async {
          refreshes++;
          return 'never';
        },
      );

      await expectLater(
        client.dio.post<dynamic>('/v1/auth/refresh'),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 0);
    });

    test('reports an expired session when renewal fails', () async {
      var expired = false;

      final client = _buildClient(
        handler: (_) => const FakeResponse(401, {
          'error': {'code': 'UNAUTHORIZED', 'message': 'expirado'},
        }),
        accessToken: 'access-1',
        refreshSession: () async => throw Exception('refresh revocado'),
        onSessionExpired: () async => expired = true,
      );

      await expectLater(
        client.dio.get<dynamic>('/v1/boxes'),
        throwsA(isA<DioException>()),
      );
      expect(expired, isTrue);
    });

    test('a failed renewal does not block later attempts', () async {
      // If the renewal-in-progress flag were not released, a passing failure
      // would leave the application waiting forever on a dead renewal.
      var attempts = 0;

      final client = _buildClient(
        handler: (options) => options.headers['Authorization'] == 'Bearer good'
            ? const FakeResponse(200, {'ok': true})
            : const FakeResponse(401, {
                'error': {'code': 'UNAUTHORIZED', 'message': 'expirado'},
              }),
        accessToken: 'access-1',
        refreshSession: () async {
          attempts++;
          if (attempts == 1) throw Exception('red caída');
          return 'good';
        },
      );

      await expectLater(
        client.dio.get<dynamic>('/v1/boxes'),
        throwsA(isA<DioException>()),
      );

      final response = await client.dio.get<dynamic>('/v1/boxes');
      expect(response.statusCode, 200);
      expect(attempts, 2);
    });

    test('leaves other error statuses alone', () async {
      var refreshes = 0;

      final client = _buildClient(
        handler: (_) => const FakeResponse(403, {
          'error': {'code': 'FORBIDDEN', 'message': 'sin permiso'},
        }),
        accessToken: 'access-1',
        refreshSession: () async {
          refreshes++;
          return 'never';
        },
      );

      await expectLater(
        client.dio.get<dynamic>('/v1/boxes'),
        throwsA(isA<DioException>()),
      );
      expect(refreshes, 0);
    });
  });
}
