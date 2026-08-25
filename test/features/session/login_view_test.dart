import 'package:araguaney_app/core/api/client_version_gate.dart';
import 'package:araguaney_app/core/api/client_version_providers.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/platform/open_link.dart';
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
    List<String>? opened,
    List<LinkTarget>? targets,
    ClientVersionStatus versionStatus = ClientVersionStatus.current,
  }) async {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWithValue('1.2.3'),
        appBuildNumberProvider.overrideWithValue('7'),
        clientVersionStatusProvider.overrideWith(
          (ref) async => (status: versionStatus, latest: '9.9.9'),
        ),
        openLinkProvider.overrideWithValue((
          url, {
          target = LinkTarget.systemApp,
        }) async {
          opened?.add(url);
          targets?.add(target);
          return true;
        }),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

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

  group('the way out for somebody without a centre', () {
    Future<void> tapLink(WidgetTester tester, List<String> opened) async {
      await pumpLogin(tester, opened: opened);
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Tu centro aún no está registrado?'));
      await tester.pumpAndSettle();
    }

    testWidgets('it opens inside the application, not beside it', (
      tester,
    ) async {
      // Es una página pública que no pide contraseña, y quien la toca sigue
      // en el acceso. Custom Tabs sigue siendo el navegador del sistema: no
      // es un WebView nuestro, así que la verificación antiabuso de la página
      // trabaja donde debe.
      final targets = <LinkTarget>[];
      await pumpLogin(tester, opened: <String>[], targets: targets);
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Tu centro aún no está registrado?'));
      await tester.pumpAndSettle();

      expect(targets, [LinkTarget.inAppBrowser]);
    });

    testWidgets('a phone in Spanish reaches the Spanish form', (tester) async {
      // Explícito: el arnés de pruebas arranca en `en_US`, así que dar por
      // hecho el español aquí probaría el caso contrario sin avisar.
      tester.platformDispatcher.localeTestValue = const Locale('es', 'VE');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);

      final opened = <String>[];
      await tapLink(tester, opened);

      expect(opened, ['http://localhost:3000/registrar-centro']);
    });

    testWidgets('a phone in English reaches the English form', (tester) async {
      // La interfaz sigue en español —es el idioma en que se opera un centro—
      // pero quien toca esto todavía no opera ninguno, y la página pública
      // existe en los dos. El slug en inglés es otro, no el mismo traducido.
      //
      // La base es la de `AppConfig`, que sin `--dart-define` es la de
      // desarrollo: eso es justo lo que se quiere fijar, que el enlace salga
      // de la configuración y no de una constante escrita en la pantalla.
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);

      final opened = <String>[];
      await tapLink(tester, opened);

      expect(opened, ['http://localhost:3000/en/register-center']);
    });

    testWidgets('any other language falls back to Spanish', (tester) async {
      tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);

      final opened = <String>[];
      await tapLink(tester, opened);

      expect(opened, ['http://localhost:3000/registrar-centro']);
    });
  });

  testWidgets('recovering a password is reachable from here', (tester) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  group('the installed version, at the foot', () {
    testWidgets('it names the build, not only the version', (tester) async {
      // El nombre se repite entre publicaciones; el que identifica un binario
      // es el numero de compilacion, que es el que hace falta para saber que
      // se esta mirando cuando alguien reporta algo.
      await pumpLogin(tester);
      await tester.pumpAndSettle();

      expect(find.text('Versión 1.2.3 (7)'), findsOneWidget);
    });

    testWidgets('a newer version is mentioned, not imposed', (tester) async {
      // Hay una nueva y no pasa nada por seguir: una interrupcion seria
      // desproporcionada. El muro es otra cosa y tiene su propia pantalla.
      await pumpLogin(
        tester,
        versionStatus: ClientVersionStatus.updateAvailable,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('más nueva'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    });

    testWidgets('a current version says nothing extra', (tester) async {
      await pumpLogin(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('más nueva'), findsNothing);
    });
  });
}
