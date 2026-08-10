import 'package:araguaney_app/app.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_auth.dart';

void main() {
  testWidgets('app boots and renders its first screen in Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWithValue('1.0.0-test'),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        ],
        child: const AraguaneyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Sin sesión guardada, la primera pantalla es el inicio de sesión.
    expect(find.text('Araguaney'), findsOneWidget);
    expect(
      find.text('Inicia sesión para operar tu centro de acopio.'),
      findsOneWidget,
    );
  });
}
