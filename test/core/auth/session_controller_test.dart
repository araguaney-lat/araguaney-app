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
      // El registro del destino de avisos sale por aquí. Sin sobrescribirlo,
      // abrir sesión intentaría hablar con el servidor de dispositivos.
      onSessionStartedProvider.overrideWithValue(onStarted ?? () async {}),
      onSessionEndingProvider.overrideWithValue(onEnding ?? () async {}),
      // Sin esto, iniciar sesión abriría la base de verdad y con ella un canal
      // de plataforma que en una prueba unitaria no existe.
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
        // `POST /v1/auth/refresh` devuelve solo los tokens. Sin preguntar quién
        // es, quien coordina un centro reaparecía como voluntariado en cada
        // reinicio: sin sus acciones y sin su rol, hasta volver a entrar.
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
      // Ofrecer de menos es la dirección segura: el servidor sigue decidiendo
      // en cada llamada, y una acción que no se ofrece no rompe nada.
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
      // El backend rota el refresh en cada uso; guardar el anterior dejaría en
      // el dispositivo una credencial ya revocada.
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
        // Sin señal no se puede volver a iniciar sesión: borrar la credencial
        // dejaría el dispositivo inservible justo donde más falta hace.
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
        // El token parcial caduca en minutos y no es una sesión: escribirlo en el
        // almacén seguro sería guardar una credencial que no abre nada.
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
      // Registrar es idempotente, así que repetirlo en cada arranque sería una
      // petición de más: quien vuelve a abrir la aplicación sigue siendo el
      // destino que registró al entrar.
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
      // El endpoint de baja exige justo la sesión que se está entregando: si el
      // borrado ocurriera antes, la llamada saldría sin credenciales y el
      // teléfono seguiría recibiendo los avisos de quien acaba de salir.
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
        // La llamada exige una sesión válida y eso es justo lo que se perdió.
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
      // El límite del inicio de sesión no se cuenta por persona: en el arranque
      // de un turno lo puede agotar el centro entero, y quien reciba el rechazo
      // tiene la contraseña correcta.
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
        // El servidor contesta 401 con `INVALID_CREDENTIALS` y un mensaje en
        // inglés —«Invalid credentials»—, no un rechazo de regla de negocio en
        // español. Este fixture decía lo segundo, así que fijaba una respuesta
        // que el servidor no manda; con la real, la pantalla llegó a decir «Tu
        // sesión expiró» a quien todavía no tenía sesión.
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
        // El limite global no es culpa de quien lo recibe; el bloqueo por
        // intentos fallidos si tiene que ver con lo que se escribio. Son dos
        // rechazos con el mismo tipo y distinto codigo.
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
      // El estado lleva el fallo y la pantalla lo redacta; aquí se comprueba
      // que llega entero el mensaje del servidor, que es lo que describe algo
      // que quien teclea puede corregir.
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
      // Seguir tecleando códigos contra una puerta ya cerrada no lleva a
      // ninguna parte.
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
