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
    bool national = false,
  }) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const []));
    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
        isNationalAdminProvider.overrideWithValue(national),
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
    // Whoever coordinates comes to verify what somebody else captured.
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

  /// The bar's destination is what gets looked at and not the screen's text:
  /// home has numbers of its own — «Capturas hoy», which may well be zero — and
  /// a loose text search confuses the counter with them.
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
    // The menu is a sheet: closing it returns to where you were, not to another
    // tab.
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

    // The menu no longer fits whole: it has to be scrolled. It is the sign that
    // it needs grouping, noted in phase 11.
    await tester.dragUntilVisible(
      find.text('Revisiones de riesgo'),
      find.byType(ListView).last,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    expect(find.text('Revisiones de riesgo'), findsOneWidget);
  });

  group('the menu is grouped, and a group that is empty is not drawn', () {
    testWidgets('somebody who captures is shown no desk work', (tester) async {
      await pumpShell(tester, coordinator: false);
      await tester.tap(find.text('Menú'));
      await tester.pumpAndSettle();

      expect(find.text('La jornada'), findsOneWidget);
      expect(find.text('El centro'), findsOneWidget);
      // A heading with nothing under it is worse than no heading.
      expect(find.text('Administración'), findsNothing);

      await tester.dragUntilVisible(
        find.text('Tu cuenta'),
        find.byType(ListView).last,
        const Offset(0, -80),
      );
      expect(find.text('Tu cuenta'), findsOneWidget);
    });

    testWidgets('administration keeps its own group, at the end', (
      tester,
    ) async {
      await pumpShell(tester, coordinator: true, national: true);
      await tester.tap(find.text('Menú'));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Administración'),
        find.byType(ListView).last,
        const Offset(0, -80),
      );
      expect(find.text('Administración'), findsOneWidget);
      expect(find.text('Centros'), findsOneWidget);
    });

    testWidgets('the account is one group and not two ends of a list', (
      tester,
    ) async {
      await pumpShell(tester, coordinator: false);
      await tester.tap(find.text('Menú'));
      await tester.pumpAndSettle();

      // All the way down: the account is the last group.
      await tester.drag(find.byType(ListView).last, const Offset(0, -1200));
      await tester.pumpAndSettle();
      // Both under the same header, and not at opposite ends of the list, which
      // is where they were.
      expect(find.text('Perfil y seguridad'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  testWidgets('the role decides the action, not the screen', (tester) async {
    final l10n = await spanish();

    expect(centerActionFor(l10n, coordinates: true).label, 'Escanear');
    expect(centerActionFor(l10n, coordinates: false).label, 'Capturar');
  });
}
