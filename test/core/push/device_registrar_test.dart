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
      // Retrofit leaves the nested objects unserialised until dio encodes
      // them; reading it typed is truer than assuming the string.
      expect(body['platform'], DeviceTokenRegisterPlatform.android);
      expect(body['app_version'], '1.2.3');
    });

    test('without a token there is nothing to register, and that is fine', () {
      // It is the `foss` flavour, a denied permission or a phone without Google
      // services. None of them is an error.
      push.token = null;
      final adapter = okAdapter();

      expect(registrarOn(adapter).register(), completion(isFalse));
      expect(adapter.requests, isEmpty);
    });

    test('a failure never reaches whoever is logging in', () async {
      // With no signal at the start of a shift this fails, and the person signs
      // in anyway.
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
      // The server answers the same whether or not it exists, so as not to
      // reveal whether somebody else's token is registered. Here that is not a
      // case to tell apart.
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
      // Every rotation leaves the previous address dead.
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

      // A registration on opening and an unregistration on closing; the
      // rotation afterwards belongs to nobody.
      expect(adapter.requests.map((r) => r.path), [
        '/v1/devices',
        '/v1/devices/unregister',
      ]);
    });

    test(
      'opening twice does not leave two listeners on the same token',
      () async {
        // A password change renews the session without closing it.
        final adapter = okAdapter();
        final binder = binderOn(adapter);
        await binder.onSessionStarted();
        await binder.onSessionStarted();

        push.rotate('fcm-token-2');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Two openings and a single registered rotation.
        expect(adapter.requests, hasLength(3));
      },
    );
  });
}
