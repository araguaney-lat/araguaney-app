import 'package:araguaney_app/core/api/client_version_gate.dart';
import 'package:araguaney_app/core/api/client_version_providers.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/platform/open_link.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/routing/session_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth.dart';

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
  }) async {
    final container = ProviderContainer(
      overrides: [
        appVersionProvider.overrideWithValue('1.0.0'),
        appBuildNumberProvider.overrideWithValue('3'),
        appPackageNameProvider.overrideWithValue('lat.araguaney.test'),
        clientVersionStatusProvider.overrideWith((ref) => status()),
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
        child: const MaterialApp(home: SessionGate()),
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
}
