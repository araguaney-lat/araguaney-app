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

/// La compuerta de versión mínima, conectada.
///
/// Estuvo escrita y probada durante seis fases sin que ningún archivo la
/// llamara, así que lo que hay que fijar no es la comparación —eso ya lo cubre
/// `client_version_gate_test.dart`— sino que el resultado llegue a la pantalla
/// y, sobre todo, **que un fallo de la comprobación no deje a nadie fuera**.
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
        appPackageNameProvider.overrideWithValue('lat.araguaney.test'),
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
    // Ni el acceso ni ninguna forma de seguir.
    expect(find.widgetWithText(TextFormField, 'Contraseña'), findsNothing);
    expect(find.text('Entrar'), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('the wall says which build is installed', (tester) async {
    // Quien llega aquí es exactamente la persona a la que hay que preguntarle
    // qué versión tiene.
    await pumpGate(
      tester,
      status: () async => ClientVersionStatus.updateRequired,
    );

    expect(find.text('Versión 1.0.0 (3)'), findsOneWidget);
  });

  testWidgets('a failed check never locks anybody out', (tester) async {
    // Es el punto entero: el endpoint es una petición más que puede agotar el
    // tiempo en un sótano, y negarse a abrir por eso sería peor que correr un
    // poco atrasado.
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
      // A diferencia del muro: la version instalada funciona, asi que seguir no
      // arriesga nada que el servidor no acepte.
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
          appPackageNameProvider.overrideWithValue('lat.araguaney.test'),
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

      // Se quita de en medio y deja pasar al acceso.
      expect(find.text('Hay una versión más nueva'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
      // Y queda anotado contra esa version, no contra la aplicacion entera.
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
      // El muro no admite «Más tarde», y llegar a ofrecerlo seria ofrecer una
      // salida que no existe.
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
      // Cinco dias, dos, y uno de ahi en adelante: si volviera cada pocas horas
      // se tocaria por reflejo, y el muro llegaria como una sorpresa.
      expect(snoozeDaysFor(0), 5);
      expect(snoozeDaysFor(1), 2);
      expect(snoozeDaysFor(2), 1);
      expect(snoozeDaysFor(9), 1);
    });
  });
}
