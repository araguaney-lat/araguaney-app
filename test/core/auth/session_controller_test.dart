import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/auth/auth_repository.dart';
import 'package:araguaney_app/core/auth/session.dart';
import 'package:araguaney_app/core/auth/session_controller.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/features/session/domain/login_failure_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';
import '../../support/l10n.dart';

({ProviderContainer container, SessionController controller}) _build({
  required FakeAuthRepository repository,
  required FakeTokenStorage storage,
  FakeReadModelReset? readModelReset,
  SessionPushHook? onStarted,
  SessionPushHook? onEnding,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      tokenStorageProvider.overrideWithValue(storage),
      // Registering the notice destination goes out through here. Without
      // overriding it, signing in would try to talk to the devices server.
      onSessionStartedProvider.overrideWithValue(onStarted ?? () async {}),
      onSessionEndingProvider.overrideWithValue(onEnding ?? () async {}),
      // Without this, signing in would open the real database and with it a
      // platform channel that does not exist in a unit test.
      readModelResetProvider.overrideWithValue(
        (readModelReset ?? FakeReadModelReset()).call,
      ),
    ],
  );
  addTearDown(container.dispose);
  return (
    container: container,
    controller: container.read(sessionControllerProvider.notifier),
  );
}

void main() {
  group('restoring on startup', () {
    test('with nothing stored there is no session', () async {
      final storage = FakeTokenStorage();
      final built = _build(repository: FakeAuthRepository(), storage: storage);

      await built.controller.restoration;

      expect(
        built.container.read(sessionControllerProvider),
        isA<SessionAbsent>(),
      );
    });

    test('rebuilds the session from the stored refresh token', () async {
      final storage = FakeTokenStorage(stored: 'refresh-stored');
      final repository = FakeAuthRepository(
        refreshToken: buildToken(access: 'access-new', refresh: 'refresh-new'),
      );
      final built = _build(repository: repository, storage: storage);

      await built.controller.restoration;

      final state = built.container.read(sessionControllerProvider);
      expect(state, isA<SessionActive>());
      expect((state as SessionActive).session.accessToken, 'access-new');
      expect(repository.lastRefreshTokenUsed, 'refresh-stored');
    });

    test(
      'a restored session keeps the role the token does not carry',
      () async {
        // `POST /v1/auth/refresh` returns the tokens only. Without asking who
        // it is, whoever coordinates a centre reappeared as a volunteer at
        // every restart: without their actions and without their role, until
        // signing in again.
        final repository = FakeAuthRepository(
          refreshToken: buildToken(centerRole: null),
        )..meCenterRole = 'coordinator';
        final built = _build(
          repository: repository,
          storage: FakeTokenStorage(stored: 'refresh-stored'),
        );

        await built.controller.restoration;

        final state = built.container.read(sessionControllerProvider);
        expect((state as SessionActive).session.centerRole, 'coordinator');
      },
    );

    test('without an answer the session opens with no role at all', () async {
      // Offering too little is the safe direction: the server goes on deciding
      // on every call, and an action that is not offered breaks nothing.
      final repository = FakeAuthRepository(
        refreshToken: buildToken(centerRole: null),
      )..meError = unauthorized;
      final built = _build(
        repository: repository,
        storage: FakeTokenStorage(stored: 'refresh-stored'),
      );

      await built.controller.restoration;

      final state = built.container.read(sessionControllerProvider);
      expect(state, isA<SessionActive>());
      expect((state as SessionActive).session.centerRole, isNull);
    });

    test('a token that carries the role is not asked about twice', () async {
      final repository = FakeAuthRepository(
        refreshToken: buildToken(centerRole: 'coordinator'),
      );
      final built = _build(
        repository: repository,
        storage: FakeTokenStorage(stored: 'refresh-stored'),
      );

      await built.controller.restoration;

      expect(repository.meCount, 0);
    });

    test('stores the rotated refresh token, replacing the old one', () async {
      // The backend rotates the refresh on every use; storing the previous one
      // would leave an already revoked credential on the device.
      final storage = FakeTokenStorage(stored: 'refresh-old');
      final built = _build(
        repository: FakeAuthRepository(
          refreshToken: buildToken(refresh: 'refresh-rotated'),
        ),
        storage: storage,
      );

      await built.controller.restoration;

      expect(storage.stored, 'refresh-rotated');
      expect(storage.written, ['refresh-rotated']);
    });

    test(
      'a network failure keeps the credential for when signal returns',
      () async {
        // With no signal there is no signing in again: deleting the credential
        // would leave the device useless exactly where it is needed most.
        final storage = FakeTokenStorage(stored: 'refresh-live');
        final built = _build(
          repository: FakeAuthRepository(
            refreshError: const NetworkFailure(message: 'sin red'),
          ),
          storage: storage,
        );

        await built.controller.restoration;

        expect(
          built.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
        expect(
          storage.stored,
          'refresh-live',
          reason: 'la credencial sobrevive',
        );
        expect(storage.clearCount, 0);
      },
    );

    test(
      'a revoked refresh token leaves the device without a session',
      () async {
        final storage = FakeTokenStorage(stored: 'refresh-revoked');
        final built = _build(
          repository: FakeAuthRepository(refreshError: unauthorized),
          storage: storage,
        );

        await built.controller.restoration;

        expect(
          built.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
        expect(storage.stored, isNull);
        expect(storage.clearCount, 1);
      },
    );
  });

  group('logging in', () {
    test('a successful login opens and persists the session', () async {
      final storage = FakeTokenStorage();
      final built = _build(
        repository: FakeAuthRepository(
          loginResult: LoginSucceeded(buildToken(refresh: 'refresh-fresh')),
        ),
        storage: storage,
      );

      await built.controller.logIn(username: 'ana', password: 'secreta');

      expect(
        built.container.read(sessionControllerProvider),
        isA<SessionActive>(),
      );
      expect(storage.stored, 'refresh-fresh');
    });

    test('wrong credentials surface the failure without a session', () async {
      final storage = FakeTokenStorage();
      final built = _build(
        repository: FakeAuthRepository(loginError: unauthorized),
        storage: storage,
      );

      await built.controller.logIn(username: 'ana', password: 'mala');

      final state = built.container.read(sessionControllerProvider);
      expect(state, isA<SessionAbsent>());
      expect((state as SessionAbsent).failure, isNotNull);
      expect(storage.written, isEmpty);
    });

    test(
      'a second factor pauses the login without persisting anything',
      () async {
        // The partial token expires in minutes and is not a session: writing it
        // to secure storage would be keeping a credential that opens nothing.
        final storage = FakeTokenStorage();
        final built = _build(
          repository: FakeAuthRepository(
            loginResult: const LoginNeedsTotp('partial-abc'),
          ),
          storage: storage,
        );

        await built.controller.logIn(username: 'ana', password: 'secreta');

        final state = built.container.read(sessionControllerProvider);
        expect(state, isA<SessionAwaitingTotp>());
        expect((state as SessionAwaitingTotp).partialToken, 'partial-abc');
        expect(storage.written, isEmpty);
      },
    );
  });

  group('the device as a destination for notices', () {
    test('opening a session registers it', () async {
      var registered = 0;
      final built = _build(
        repository: FakeAuthRepository(
          loginResult: LoginSucceeded(buildToken()),
        ),
        storage: FakeTokenStorage(),
        onStarted: () async => registered++,
      );
      await built.controller.restoration;

      await built.controller.logIn(username: 'p', password: 'x');

      expect(registered, 1);
    });

    test('restoring a session does not register again', () async {
      // Registering is idempotent, so repeating it at every launch would be one
      // request too many: whoever reopens the application is still the
      // destination they registered on the way in.
      var registered = 0;
      final built = _build(
        repository: FakeAuthRepository(refreshToken: buildToken()),
        storage: FakeTokenStorage(stored: 'refresh-stored'),
        onStarted: () async => registered++,
      );

      await built.controller.restoration;

      expect(registered, 0);
    });

    test('closing a session drops it **before** the session is gone', () async {
      // The unregister endpoint requires the very session being handed back: if
      // the deletion happened first, the call would go out with no credentials
      // and the phone would go on receiving the notices of whoever just left.
      final storage = FakeTokenStorage(stored: 'refresh-1');
      late ProviderContainer container;
      SessionState? stateWhenDropped;
      int? clearsWhenDropped;

      final built = _build(
        repository: FakeAuthRepository(refreshToken: buildToken()),
        storage: storage,
        onEnding: () async {
          stateWhenDropped = container.read(sessionControllerProvider);
          clearsWhenDropped = storage.clearCount;
        },
      );
      container = built.container;
      await built.controller.restoration;

      await built.controller.logOut();

      expect(stateWhenDropped, isA<SessionActive>());
      expect(clearsWhenDropped, 0);
      expect(storage.clearCount, 1);
    });

    test(
      'an expired session cannot drop it, and does not pretend to',
      () async {
        // The call requires a valid session and that is exactly what was lost.
        var dropped = 0;
        final built = _build(
          repository: FakeAuthRepository(),
          storage: FakeTokenStorage(stored: 'refresh-1'),
          onEnding: () async => dropped++,
        );
        await built.controller.restoration;

        await built.controller.expire();

        expect(dropped, 0);
      },
    );
  });

  group('rate limiting at the door', () {
    test('too many attempts is never reported as a bad password', () async {
      // The sign-in limit is not counted per person: at the start of a shift the
      // whole centre can exhaust it, and whoever gets the refusal has the right
      // password.
      final repository = FakeAuthRepository(
        loginError: const RateLimitFailure(
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'Too many requests',
        ),
      );
      final built = _build(repository: repository, storage: FakeTokenStorage());
      await built.controller.restoration;

      await built.controller.logIn(username: 'persona', password: 'correcta');

      final state =
          built.container.read(sessionControllerProvider) as SessionAbsent;
      expect(
        loginFailureMessage(await spanish(), state.failure!),
        contains('no es tu contraseña'),
      );
      expect(
        loginFailureMessage(await spanish(), state.failure!),
        isNot(contains('Credenciales')),
      );
    });

    test(
      'a real credentials rejection says the credentials do not match',
      () async {
        // The server answers 401 with `INVALID_CREDENTIALS` and a message in
        // English — «Invalid credentials» — not a business-rule refusal in
        // Spanish. This fixture said the second, so it pinned an answer the
        // server does not send; with the real one, the screen got as far as
        // telling somebody who had no session yet that theirs had expired.
        final repository = FakeAuthRepository(
          loginError: const UnauthorizedFailure(
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid credentials',
          ),
        );
        final built = _build(
          repository: repository,
          storage: FakeTokenStorage(),
        );
        await built.controller.restoration;

        await built.controller.logIn(username: 'persona', password: 'mala');

        final state =
            built.container.read(sessionControllerProvider) as SessionAbsent;
        expect(
          loginFailureMessage(await spanish(), state.failure!),
          'El correo o la contraseña no coinciden.',
        );
        expect(
          loginFailureMessage(await spanish(), state.failure!),
          isNot(contains('sesión expiró')),
        );
      },
    );

    test(
      'a locked account is not told that it is not their password',
      () async {
        // The global limit is not the fault of whoever receives it; a block for
        // failed attempts does have to do with what was typed. They are two
        // refusals with the same type and a different code.
        const locked = RateLimitFailure(
          code: 'ACCOUNT_LOCKED',
          message: 'Too many failed attempts.',
        );

        expect(
          locked.operatorMessage(await spanish()),
          contains('intentos fallidos'),
        );
        expect(
          locked.operatorMessage(await spanish()),
          isNot(contains('no es tu contraseña')),
        );
      },
    );
  });

  group('second factor', () {
    test('a valid code opens the session', () async {
      final repository = FakeAuthRepository(
        loginResult: const LoginNeedsTotp('partial-abc'),
        totpToken: buildToken(access: 'access-totp'),
      );
      final built = _build(repository: repository, storage: FakeTokenStorage());

      await built.controller.logIn(username: 'ana', password: 'secreta');
      await built.controller.submitTotpCode('123456');

      final state = built.container.read(sessionControllerProvider);
      expect(state, isA<SessionActive>());
      expect((state as SessionActive).session.accessToken, 'access-totp');
    });

    test('a wrong code keeps the challenge open with its reason', () async {
      final repository = FakeAuthRepository(
        loginResult: const LoginNeedsTotp('partial-abc'),
        totpError: wrongCode,
      );
      final built = _build(repository: repository, storage: FakeTokenStorage());

      await built.controller.logIn(username: 'ana', password: 'secreta');
      await built.controller.submitTotpCode('000000');

      final state = built.container.read(sessionControllerProvider);
      expect(state, isA<SessionAwaitingTotp>());
      // The state carries the failure and the screen words it; what is checked
      // here is that the server's message arrives whole, because it is the one
      // that describes something whoever types can correct.
      expect(
        loginFailureMessage(
          await spanish(),
          (state as SessionAwaitingTotp).failure!,
        ),
        'El código no es válido',
      );
      expect(state.partialToken, 'partial-abc');
    });

    test('an expired partial token returns to the login screen', () async {
      // Going on typing codes against a door that is already shut leads
      // nowhere.
      final repository = FakeAuthRepository(
        loginResult: const LoginNeedsTotp('partial-abc'),
        totpError: unauthorized,
      );
      final built = _build(repository: repository, storage: FakeTokenStorage());

      await built.controller.logIn(username: 'ana', password: 'secreta');
      await built.controller.submitTotpCode('123456');

      expect(
        built.container.read(sessionControllerProvider),
        isA<SessionAbsent>(),
      );
    });
  });

  group('renewal and closing', () {
    test('renewal returns the new token and stores the rotated one', () async {
      final storage = FakeTokenStorage(stored: 'refresh-old');
      final repository = FakeAuthRepository(
        refreshToken: buildToken(access: 'access-2', refresh: 'refresh-2'),
      );
      final built = _build(repository: repository, storage: storage);

      final token = await built.controller.renew();

      expect(token, 'access-2');
      expect(storage.stored, 'refresh-2');
    });

    test('renewal without any credential fails instead of hanging', () async {
      final built = _build(
        repository: FakeAuthRepository(),
        storage: FakeTokenStorage(),
      );

      await expectLater(built.controller.renew(), throwsA(isA<Object>()));
    });

    test('logging out revokes on the server and wipes the device', () async {
      final storage = FakeTokenStorage();
      final repository = FakeAuthRepository(
        loginResult: LoginSucceeded(buildToken(refresh: 'refresh-live')),
      );
      final built = _build(repository: repository, storage: storage);

      await built.controller.logIn(username: 'ana', password: 'secreta');
      await built.controller.logOut();

      expect(repository.logoutCount, 1);
      expect(repository.lastLogoutRefreshToken, 'refresh-live');
      expect(storage.stored, isNull);
      expect(
        built.container.read(sessionControllerProvider),
        isA<SessionAbsent>(),
      );
    });

    test('expiring wipes the device and explains why', () async {
      final storage = FakeTokenStorage(stored: 'refresh-live');
      final built = _build(repository: FakeAuthRepository(), storage: storage);

      await built.controller.expire();

      final state = built.container.read(sessionControllerProvider);
      expect(state, isA<SessionAbsent>());
      expect((state as SessionAbsent).failure, isNotNull);
      expect(storage.clearCount, greaterThan(0));
    });
  });

  group('forced password change', () {
    test('the flag travels from the server into the session', () async {
      final built = _build(
        repository: FakeAuthRepository(
          loginResult: LoginSucceeded(buildToken(mustChangePassword: true)),
        ),
        storage: FakeTokenStorage(),
      );

      await built.controller.logIn(username: 'ana', password: 'temporal');

      final state =
          built.container.read(sessionControllerProvider) as SessionActive;
      expect(state.session.mustChangePassword, isTrue);
    });

    test(
      'changing the password clears the flag and renews the session',
      () async {
        final storage = FakeTokenStorage();
        final built = _build(
          repository: FakeAuthRepository(
            loginResult: LoginSucceeded(buildToken(mustChangePassword: true)),
            changePasswordToken: buildToken(
              access: 'access-after-change',
              refresh: 'refresh-after-change',
            ),
          ),
          storage: storage,
        );

        await built.controller.logIn(username: 'ana', password: 'temporal');
        await built.controller.changePassword(
          currentPassword: 'temporal',
          newPassword: 'una-nueva',
        );

        final state =
            built.container.read(sessionControllerProvider) as SessionActive;
        expect(state.session.mustChangePassword, isFalse);
        expect(state.session.accessToken, 'access-after-change');
        expect(storage.stored, 'refresh-after-change');
      },
    );
  });
}
