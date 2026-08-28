import 'package:araguaney_app/core/api/client_version_gate.dart';
import 'package:araguaney_app/core/api/client_version_providers.dart';
import 'package:araguaney_app/core/api/update_prompt_memory.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/platform/open_link.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/routing/session_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';
import '../../support/fake_update_prompt_memory.dart';

/// The minimum-version gate, wired up.
///
/// It sat written and tested for six phases without a single file calling it,
/// so what has to be pinned is not the comparison — `client_version_gate_test`
/// already covers that — but that the result reaches the screen and, above all,
/// **that a failure of the check leaves nobody out**.
void main() {
  Future<void> pumpGate(
    WidgetTester tester, {
    required Future<ClientVersionStatus> Function() status,
    String? latest,
    bool snoozed = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWithValue('1.0.0'),
        appBuildNumberProvider.overrideWithValue('3'),
        appPackageNameProvider.overrideWithValue('org.araguaney.test'),
        clientVersionStatusProvider.overrideWith(
          (ref) async => (status: await status(), latest: latest),
        ),
        updatePromptMemoryProvider.overrideWithValue(
          FakeUpdatePromptMemory(snoozed: snoozed),
        ),
        openLinkProvider.overrideWithValue(
          (url, {target = LinkTarget.systemApp}) async => true,
        ),
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SessionGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('below the minimum there is a wall and no way past it', (
    tester,
  ) async {
    await pumpGate(
      tester,
      status: () async => ClientVersionStatus.updateRequired,
    );

    expect(find.text('Esta versión ya no funciona'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    // Neither the sign-in screen nor any way of carrying on.
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsNothing);
    expect(find.text('Entrar'), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the wall says which build is installed', (tester) async {
    // Whoever gets here is exactly the person to ask which version they have.
    await pumpGate(
      tester,
      status: () async => ClientVersionStatus.updateRequired,
    );

    expect(find.text('Versión 1.0.0 (3)'), findsOneWidget);
  });

  testWidgets('a failed check never locks anybody out', (tester) async {
    // That is the whole point: the endpoint is one more request that can time
    // out in a basement, and refusing to open over it would be worse than
    // running slightly behind.
    await pumpGate(tester, status: () async => throw Exception('sin red'));

    expect(find.text('Esta versión ya no funciona'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
  });

  testWidgets('an unknown answer does not interpose either', (tester) async {
    await pumpGate(tester, status: () async => ClientVersionStatus.unknown);

    expect(find.text('Esta versión ya no funciona'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
  });

  testWidgets('a newer version available does not interpose', (tester) async {
    await pumpGate(
      tester,
      status: () async => ClientVersionStatus.updateAvailable,
    );

    expect(find.text('Esta versión ya no funciona'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
  });

  group('a newer version is offered at launch and can wait', () {
    testWidgets('it offers both, and the way out is real', (tester) async {
      // Unlike the wall: the installed version works, so carrying on risks
      // nothing the server will not accept.
      await pumpGate(
        tester,
        status: () async => ClientVersionStatus.updateAvailable,
        latest: '2.0.0',
      );

      expect(find.text('Hay una versión más nueva'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
      expect(find.text('Más tarde'), findsOneWidget);
      expect(find.textContaining('siguen en el teléfono'), findsOneWidget);
    });

    testWidgets('«later» gets out of the way and is remembered', (
      tester,
    ) async {
      final memory = FakeUpdatePromptMemory();
      final container = ProviderContainer(
        overrides: [
          appVersionProvider.overrideWithValue('1.0.0'),
          appBuildNumberProvider.overrideWithValue('3'),
          appPackageNameProvider.overrideWithValue('org.araguaney.test'),
          clientVersionStatusProvider.overrideWith(
            (ref) async =>
                (status: ClientVersionStatus.updateAvailable, latest: '2.0.0'),
          ),
          updatePromptMemoryProvider.overrideWithValue(memory),
          openLinkProvider.overrideWithValue(
            (url, {target = LinkTarget.systemApp}) async => true,
          ),
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
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SessionGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Más tarde'));
      await tester.pumpAndSettle();

      // It gets out of the way and lets the sign-in screen through.
      expect(find.text('Hay una versión más nueva'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
      // And it is noted against that version, not against the whole
      // application.
      expect(memory.snoozedVersions, ['2.0.0']);
    });

    testWidgets('while it is snoozed it does not appear', (tester) async {
      await pumpGate(
        tester,
        status: () async => ClientVersionStatus.updateAvailable,
        latest: '2.0.0',
        snoozed: true,
      );

      expect(find.text('Hay una versión más nueva'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
    });

    testWidgets('being below the minimum wins over it', (tester) async {
      // The wall takes no «later», and getting as far as offering one would be
      // offering a way out that does not exist.
      await pumpGate(
        tester,
        status: () async => ClientVersionStatus.updateRequired,
        latest: '2.0.0',
      );

      expect(find.text('Esta versión ya no funciona'), findsOneWidget);
      expect(find.text('Más tarde'), findsNothing);
    });
  });

  group('how long «later» lasts', () {
    test('it starts long and tightens with each dismissal', () {
      // Five days, two, and one from there on: if it came back every few hours
      // it would be dismissed by reflex, and the wall would arrive as a
      // surprise.
      expect(snoozeDaysFor(0), 5);
      expect(snoozeDaysFor(1), 2);
      expect(snoozeDaysFor(2), 1);
      expect(snoozeDaysFor(9), 1);
    });
  });
}
