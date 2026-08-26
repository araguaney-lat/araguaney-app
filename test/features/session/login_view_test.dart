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

  /// `MaterialApp`'s route brings its own `FadeTransition`, so what must be
  /// kept is the one closest to the tree and not just any of them.
  double markOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(
        find
            .ancestor(of: markFinder(), matching: find.byType(FadeTransition))
            .first,
      )
      .opacity
      .value;

  testWidgets('the login shows the mark', (tester) async {
    // The system splash draws this tree and the sign-in screen draws it again;
    // for months the sign-in was the gap between the two.
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
    // Whoever arrives here lost their session, sometimes mid-shift. The fields
    // respond from the first frame; nothing waits for the tween.
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
    // Motion sensitivity is not a preference a brand gets to override: with
    // animations off the final state is drawn and that is that.
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
      // It is a public page that asks for no password, and whoever taps it
      // stays on the sign-in screen. Custom Tabs is still the system browser:
      // it is not a WebView of ours, so the page's anti-abuse check works where
      // it should.
      final targets = <LinkTarget>[];
      await pumpLogin(tester, opened: <String>[], targets: targets);
      await tester.pumpAndSettle();
      await tester.tap(find.text('¿Tu centro aún no está registrado?'));
      await tester.pumpAndSettle();

      expect(targets, [LinkTarget.inAppBrowser]);
    });

    testWidgets('a phone in Spanish reaches the Spanish form', (tester) async {
      // Explicit: the test harness starts in `en_US`, so taking Spanish for
      // granted here would test the opposite case without saying so.
      tester.platformDispatcher.localeTestValue = const Locale('es', 'VE');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);

      final opened = <String>[];
      await tapLink(tester, opened);

      expect(opened, ['http://localhost:3000/registrar-centro']);
    });

    testWidgets('a phone in English reaches the English form', (tester) async {
      // The interface stays in Spanish — it is the language a centre is
      // operated in — but whoever taps this does not operate one yet, and the
      // public page exists in both. The English slug is another one, not the
      // same one translated.
      //
      // The base is `AppConfig`'s, which without `--dart-define` is the
      // development one: that is exactly what this pins down, that the link
      // comes from the configuration and not from a constant written into the
      // screen.
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
      // The name repeats between releases; what identifies a binary is the
      // build number, which is the one needed to know what is being looked at
      // when somebody reports something.
      await pumpLogin(tester);
      await tester.pumpAndSettle();

      expect(find.text('Versión 1.2.3 (7)'), findsOneWidget);
    });

    testWidgets('a newer version is mentioned, not imposed', (tester) async {
      // There is a new one and nothing happens by carrying on: an interruption
      // would be out of proportion. The wall is another thing and has its own
      // screen.
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
