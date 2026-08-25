import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/ui/app_bottom_bar.dart';
import 'package:araguaney_app/features/messaging/data/messaging_providers.dart';
import 'package:araguaney_app/features/shell/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fake_push.dart';
import '../../support/l10n.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required bool coordinator,
    int unread = 0,
  }) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const []));
    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
        unreadMessagesProvider.overrideWith((ref) async => unread),
        pushServiceProvider.overrideWithValue(FakePushService(token: 'fcm-1')),
        appVersionProvider.overrideWithValue('1.0.0+1'),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the bar carries four destinations and one action', (
    tester,
  ) async {
    await pumpShell(tester, coordinator: false);

    for (final label in ['Inicio', 'Cajas', 'Mensajes', 'Menú']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.byType(AppBottomBar), findsOneWidget);
  });

  testWidgets('coordination gets scanning as the central action', (
    tester,
  ) async {
    // Quien coordina llega a verificar lo que capturó otra persona.
    await pumpShell(tester, coordinator: true);

    expect(find.byTooltip('Escanear'), findsOneWidget);
    expect(find.byTooltip('Capturar'), findsNothing);
  });

  testWidgets('volunteering gets capturing as the central action', (
    tester,
  ) async {
    await pumpShell(tester, coordinator: false);

    expect(find.byTooltip('Capturar'), findsOneWidget);
    expect(find.byTooltip('Escanear'), findsNothing);
  });

  /// Se mira el destino de la barra y no el texto de la pantalla: el inicio
  /// tiene sus propios números —«Capturas hoy», que bien puede ser cero— y una
  /// búsqueda por texto suelto confunde el contador con ellos.
  int badgeOf(WidgetTester tester, String label) => tester
      .widget<AppBottomBar>(find.byType(AppBottomBar))
      .items
      .firstWhere((item) => item.label == label)
      .badge;

  testWidgets('unread messages are counted on their destination', (
    tester,
  ) async {
    await pumpShell(tester, coordinator: false, unread: 3);

    expect(badgeOf(tester, 'Mensajes'), 3);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('nothing is counted when there is nothing unread', (
    tester,
  ) async {
    await pumpShell(tester, coordinator: false);

    expect(badgeOf(tester, 'Mensajes'), 0);
  });

  testWidgets('the menu opens without leaving the screen behind', (
    tester,
  ) async {
    // El menú es una hoja: al cerrarla se vuelve a donde se estaba, no a otra
    // pestaña.
    await pumpShell(tester, coordinator: false);

    await tester.tap(find.text('Menú'));
    await tester.pumpAndSettle();

    expect(find.text('Tarimas'), findsOneWidget);
    expect(find.text('Transferencias'), findsOneWidget);
  });

  testWidgets('risk reviews are offered only to coordination', (tester) async {
    await pumpShell(tester, coordinator: false);
    await tester.tap(find.text('Menú'));
    await tester.pumpAndSettle();

    expect(find.text('Revisiones de riesgo'), findsNothing);
  });

  testWidgets('coordination finds risk reviews in the menu', (tester) async {
    await pumpShell(tester, coordinator: true);
    await tester.tap(find.text('Menú'));
    await tester.pumpAndSettle();

    expect(find.text('Revisiones de riesgo'), findsOneWidget);
  });

  testWidgets('the role decides the action, not the screen', (tester) async {
    final l10n = await spanish();

    expect(centerActionFor(l10n, coordinates: true).label, 'Escanear');
    expect(centerActionFor(l10n, coordinates: false).label, 'Capturar');
  });
}
