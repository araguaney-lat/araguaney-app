import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/features/session/ui/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';

void main() {
  Future<void> pumpLogin(
    WidgetTester tester, {
    bool disableAnimations = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
        onSessionStartedProvider.overrideWithValue(() async {}),
        onSessionEndingProvider.overrideWithValue(() async {}),
        readModelResetProvider.overrideWithValue(FakeReadModelReset().call),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: const LoginView(),
          ),
        ),
      ),
    );
  }

  Finder markFinder() => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == 'assets/icon/ic_mark_lg.png',
  );

  /// La ruta de `MaterialApp` trae su propio `FadeTransition`, así que hay que
  /// quedarse con el más cercano al árbol y no con cualquiera.
  double markOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(of: markFinder(), matching: find.byType(FadeTransition))
            .first,
      )
      .opacity
      .value;

  testWidgets('the login shows the mark', (tester) async {
    // El splash del sistema dibuja este árbol y el inicio lo vuelve a dibujar;
    // durante meses el acceso fue el hueco entre los dos.
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    expect(markFinder(), findsOneWidget);
  });

  testWidgets('the mark carries the name for anyone who cannot see it', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(markFinder());
    expect(image.semanticLabel, 'Araguaney');
  });

  testWidgets('the animation does not hold the form', (tester) async {
    // Quien llega aquí se quedó sin sesión, a veces a mitad de un turno. Los
    // campos responden desde el primer fotograma; nada espera al tween.
    await pumpLogin(tester);
    await tester.pump(const Duration(milliseconds: 16));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo o usuario'),
      'ana',
    );
    expect(find.text('ana'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('it starts hidden and ends whole', (tester) async {
    await pumpLogin(tester);
    await tester.pump();

    expect(markOpacity(tester), 0);
    await tester.pumpAndSettle();
    expect(markOpacity(tester), 1);
  });

  testWidgets('with animations disabled the tree is simply there', (
    tester,
  ) async {
    // La sensibilidad al movimiento no es una preferencia que una marca pueda
    // pisar: con las animaciones apagadas se dibuja el estado final y ya.
    await pumpLogin(tester, disableAnimations: true);
    await tester.pump();

    expect(markOpacity(tester), 1);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });
}
