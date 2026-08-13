import 'package:araguaney_app/app.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/auth/auth_repository.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';
import '../../support/fake_push.dart';

Widget _appWith({
  required FakeAuthRepository repository,
  required FakeTokenStorage storage,
}) => ProviderScope(
  overrides: [
    appVersionProvider.overrideWithValue('1.0.0-test'),
    // Con sesión, la puerta construye el enrutador de avisos y la tarjeta del
    // permiso. Sin doble, las dos irían a buscar Firebase.
    pushServiceProvider.overrideWithValue(FakePushService()),
    authRepositoryProvider.overrideWithValue(repository),
    tokenStorageProvider.overrideWithValue(storage),
  ],
  child: const AraguaneyApp(),
);

void main() {
  testWidgets('with no stored session it lands on the login screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWith(repository: FakeAuthRepository(), storage: FakeTokenStorage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Correo o usuario'), findsOneWidget);
  });

  testWidgets('a restored session goes straight to the application', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWith(
        repository: FakeAuthRepository(refreshToken: buildToken()),
        storage: FakeTokenStorage(stored: 'refresh-stored'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsNothing);
    expect(find.text('Araguaney'), findsWidgets);
  });

  testWidgets('a second factor request shows the code screen', (tester) async {
    await tester.pumpWidget(
      _appWith(
        repository: FakeAuthRepository(
          loginResult: const LoginNeedsTotp('partial-abc'),
        ),
        storage: FakeTokenStorage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'ana');
    await tester.enterText(find.byType(TextFormField).last, 'secreta');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Verificación en dos pasos'), findsOneWidget);
    expect(find.text('Código de 6 dígitos'), findsOneWidget);
  });

  testWidgets('a forced password change is interposed before the app', (
    tester,
  ) async {
    // La clave temporal tiene que dejar de servir en cuanto se usa; saltarse
    // esta pantalla la dejaría viva.
    await tester.pumpWidget(
      _appWith(
        repository: FakeAuthRepository(
          refreshToken: buildToken(mustChangePassword: true),
        ),
        storage: FakeTokenStorage(stored: 'refresh-stored'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cambia tu contraseña'), findsOneWidget);
    expect(find.text('Guardar y continuar'), findsOneWidget);
  });

  testWidgets('a failed login shows the reason on the login screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWith(
        repository: FakeAuthRepository(loginError: unauthorized),
        storage: FakeTokenStorage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'ana');
    await tester.enterText(find.byType(TextFormField).last, 'mala');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu sesión expiró. Inicia sesión de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('empty fields are caught before spending a request', (
    tester,
  ) async {
    final repository = FakeAuthRepository(loginError: unauthorized);
    await tester.pumpWidget(
      _appWith(repository: repository, storage: FakeTokenStorage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu correo o usuario'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
  });
}
