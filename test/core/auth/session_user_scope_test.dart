import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/auth/auth_repository.dart';
import 'package:araguaney_app/core/auth/session.dart';
import 'package:araguaney_app/core/auth/session_controller.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';

/// El cache de lectura es por persona. Un dispositivo de centro se comparte
/// entre turnos, y lo que se consultó en uno no puede quedar a la vista del
/// siguiente.
({
  ProviderContainer container,
  SessionController controller,
  FakeReadModelReset reset,
})
_build({
  required FakeAuthRepository repository,
  required FakeTokenStorage storage,
}) {
  final reset = FakeReadModelReset();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(storage),
      readModelResetProvider.overrideWithValue(reset.call),
      onSessionStartedProvider.overrideWithValue(() async {}),
      onSessionEndingProvider.overrideWithValue(() async {}),
    ],
  );
  addTearDown(container.dispose);
  return (
    container: container,
    controller: container.read(sessionControllerProvider.notifier),
    reset: reset,
  );
}

Session _sessionOf(ProviderContainer container) =>
    (container.read(sessionControllerProvider) as SessionActive).session;

void main() {
  group('logging in', () {
    test('a different person wipes what the previous shift cached', () async {
      final storage = FakeTokenStorage(storedUserId: 'user-morning');
      final repository = FakeAuthRepository(
        loginResult: LoginSucceeded(buildToken()),
      )..meUserId = 'user-evening';
      final built = _build(repository: repository, storage: storage);
      await built.controller.restoration;

      await built.controller.logIn(username: 'p', password: 'x');

      expect(built.reset.count, 1);
      expect(storage.storedUserId, 'user-evening');
      expect(_sessionOf(built.container).userId, 'user-evening');
    });

    test('the same person keeps their cache', () async {
      final storage = FakeTokenStorage(storedUserId: 'user-1');
      final repository = FakeAuthRepository(
        loginResult: LoginSucceeded(buildToken()),
      )..meUserId = 'user-1';
      final built = _build(repository: repository, storage: storage);
      await built.controller.restoration;

      await built.controller.logIn(username: 'p', password: 'x');

      expect(built.reset.count, 0);
    });

    test('an unconfirmed identity wipes: failing closed is the only safe '
        'direction on a shared device', () async {
      final storage = FakeTokenStorage(storedUserId: 'user-1');
      final repository = FakeAuthRepository(
        loginResult: LoginSucceeded(buildToken()),
      )..meError = unauthorized;
      final built = _build(repository: repository, storage: storage);
      await built.controller.restoration;

      await built.controller.logIn(username: 'p', password: 'x');

      expect(built.reset.count, 1);
      expect(storage.storedUserId, isNull);
      expect(_sessionOf(built.container).userId, isNull);
    });

    test('a first install wipes an empty database and moves on', () async {
      final storage = FakeTokenStorage();
      final repository = FakeAuthRepository(
        loginResult: LoginSucceeded(buildToken()),
      )..meUserId = 'user-1';
      final built = _build(repository: repository, storage: storage);
      await built.controller.restoration;

      await built.controller.logIn(username: 'p', password: 'x');

      expect(built.reset.count, 1);
      expect(storage.storedUserId, 'user-1');
    });
  });

  group('second factor', () {
    test('identity is resolved after the code, not before it', () async {
      final storage = FakeTokenStorage(storedUserId: 'user-morning');
      final repository = FakeAuthRepository(
        loginResult: const LoginNeedsTotp('partial-1'),
        totpToken: buildToken(),
      )..meUserId = 'user-evening';
      final built = _build(repository: repository, storage: storage);
      await built.controller.restoration;

      await built.controller.logIn(username: 'p', password: 'x');
      expect(repository.meCount, 0);

      await built.controller.submitTotpCode('123456');

      expect(repository.meCount, 1);
      expect(built.reset.count, 1);
    });
  });

  group('restoring and renewing', () {
    test(
      'restoring reuses the stored identity without asking the server',
      () async {
        final storage = FakeTokenStorage(
          stored: 'refresh-stored',
          storedUserId: 'user-1',
        );
        final repository = FakeAuthRepository(refreshToken: buildToken());
        final built = _build(repository: repository, storage: storage);

        await built.controller.restoration;

        // Un refresh guardado no se convierte en otra persona: preguntar sería
        // una petición de más en el arranque, y sin señal ni siquiera es posible.
        expect(repository.meCount, 0);
        expect(built.reset.count, 0);
        expect(_sessionOf(built.container).userId, 'user-1');
      },
    );

    test('renewing keeps the identity of the session it renews', () async {
      final storage = FakeTokenStorage(
        stored: 'refresh-stored',
        storedUserId: 'user-1',
      );
      final repository = FakeAuthRepository(refreshToken: buildToken());
      final built = _build(repository: repository, storage: storage);
      await built.controller.restoration;

      await built.controller.renew();

      expect(repository.meCount, 0);
      expect(built.reset.count, 0);
      expect(_sessionOf(built.container).userId, 'user-1');
    });
  });
}
