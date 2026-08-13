import 'package:araguaney_app/core/api/generated/clients/devices_api.dart';
import 'package:araguaney_app/core/api/generated/models/device_token_register_platform.dart';
import 'package:araguaney_app/core/push/device_registrar.dart';
import 'package:araguaney_app/core/push/push_session_binder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fake_push.dart';

void main() {
  late FakePushService push;

  setUp(() => push = FakePushService(token: 'fcm-token-1'));
  tearDown(() => push.dispose());

  DeviceRegistrar registrarOn(FakeHttpAdapter adapter) => DeviceRegistrar(
    api: DevicesApi(fakeDio(adapter)),
    push: push,
    appVersion: '1.2.3',
    platform: DeviceTokenRegisterPlatform.android,
  );

  FakeHttpAdapter okAdapter() =>
      FakeHttpAdapter((_) => FakeResponse(200, {'ok': true}));

  group('registering', () {
    test('sends the token, the platform and the installed version', () async {
      final adapter = okAdapter();

      final done = await registrarOn(adapter).register();

      expect(done, isTrue);
      final request = adapter.requests.single;
      expect(request.path, '/v1/devices');
      final body = request.data as Map<String, dynamic>;
      expect(body['token'], 'fcm-token-1');
      // Retrofit deja los objetos anidados sin serializar hasta que dio los
      // codifica; leerlo tipado es más fiel que asumir la cadena.
      expect(body['platform'], DeviceTokenRegisterPlatform.android);
      expect(body['app_version'], '1.2.3');
    });

    test('without a token there is nothing to register, and that is fine', () {
      // Es el sabor `foss`, un permiso denegado o un teléfono sin servicios de
      // Google. Ninguno es un error.
      push.token = null;
      final adapter = okAdapter();

      expect(registrarOn(adapter).register(), completion(isFalse));
      expect(adapter.requests, isEmpty);
    });

    test('a failure never reaches whoever is logging in', () async {
      // Sin señal al arrancar un turno esto falla, y la persona entra igual.
      final done = await registrarOn(OfflineHttpAdapter()).register();

      expect(done, isFalse);
    });
  });

  group('unregistering', () {
    test('asks the server to drop this device', () async {
      final adapter = okAdapter();

      final done = await registrarOn(adapter).unregister();

      expect(done, isTrue);
      expect(adapter.requests.single.path, '/v1/devices/unregister');
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['token'], 'fcm-token-1');
    });

    test('a token that was not ours answers 200 and that is a success', () {
      // El servidor responde igual exista o no, para no revelar si un token
      // ajeno está registrado. Aquí eso no es un caso a distinguir.
      expect(registrarOn(okAdapter()).unregister(), completion(isTrue));
    });

    test('a failure never traps someone inside a session they are closing', () {
      expect(
        registrarOn(OfflineHttpAdapter()).unregister(),
        completion(isFalse),
      );
    });
  });

  group('binding it to a session', () {
    PushSessionBinder binderOn(FakeHttpAdapter adapter) =>
        PushSessionBinder(push: push, registrar: registrarOn(adapter));

    test('opening a session starts the service and registers', () async {
      final adapter = okAdapter();

      await binderOn(adapter).onSessionStarted();

      expect(push.startCount, 1);
      expect(adapter.requests.single.path, '/v1/devices');
    });

    test('a rotated token is registered without a new session', () async {
      // Cada rotación deja muerta la dirección anterior.
      final adapter = okAdapter();
      await binderOn(adapter).onSessionStarted();

      push.rotate('fcm-token-2');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(adapter.requests, hasLength(2));
      final body = adapter.requests.last.data as Map<String, dynamic>;
      expect(body['token'], 'fcm-token-2');
    });

    test('closing a session stops listening to rotations', () async {
      final adapter = okAdapter();
      final binder = binderOn(adapter);
      await binder.onSessionStarted();

      await binder.onSessionEnding();
      push.rotate('fcm-token-3');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Registro de apertura y baja de cierre; la rotación posterior no
      // pertenece a nadie.
      expect(adapter.requests.map((r) => r.path), [
        '/v1/devices',
        '/v1/devices/unregister',
      ]);
    });

    test(
      'opening twice does not leave two listeners on the same token',
      () async {
        // Un cambio de contraseña renueva la sesión sin cerrarla.
        final adapter = okAdapter();
        final binder = binderOn(adapter);
        await binder.onSessionStarted();
        await binder.onSessionStarted();

        push.rotate('fcm-token-2');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Dos aperturas y una sola rotación registrada.
        expect(adapter.requests, hasLength(3));
      },
    );
  });
}
