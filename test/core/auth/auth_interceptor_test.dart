import 'package:araguaney_app/core/auth/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

/// Monta un cliente con el interceptor y un adaptador falso.
///
/// El reintento usa un cliente aparte, igual que en la aplicación: si viajara
/// por el mismo cliente, un 401 durante la renovación dispararía otra.
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
      // Mandar una credencial vieja al iniciar sesión no aporta nada y filtra
      // el token de quien usó el dispositivo antes.
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
          // La primera pasada vence; tras renovar, la petición reenviada lleva
          // el token nuevo y pasa.
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
      // Al abrir una pantalla salen varias peticiones juntas. Como el backend
      // rota el refresh en cada uso, una segunda renovación llegaría con un
      // token ya revocado y el servidor lo leería como reutilización.
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
      // Si tras renovar vuelve un 401, el problema no es el token.
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
      // Si la marca de renovación en curso no se liberara, un fallo pasajero
      // dejaría a la aplicación esperando para siempre una renovación muerta.
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
