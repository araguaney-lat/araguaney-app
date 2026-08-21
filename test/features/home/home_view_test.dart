import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/home/ui/home_view.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/intake/ui/pending_captures_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fake_push.dart';
import '../../support/fixtures.dart';

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    required bool coordinator,
    int pending = 0,
    int codes = 0,
    List<Map<String, Object?>>? reviews,
    List<Map<String, Object?>>? intakes,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.contains('risk-reviews')) {
        return FakeResponse(200, reviews ?? const []);
      }
      if (options.path.endsWith('/v1/intakes')) {
        return FakeResponse(200, intakes ?? const []);
      }
      if (options.path.contains('dashboard/national')) {
        return FakeResponse(200, {
          'by_category': const <Map<String, Object?>>[],
          'by_center': const <Map<String, Object?>>[],
          'by_inn': const <Map<String, Object?>>[],
          'totals': {
            'active_centers': 1,
            'total_boxes_sealed': 12,
            'total_intakes': 30,
            'total_shipments_sent': 2,
            'total_units_sealed': 480,
            'total_weight_kg': 86.4,
          },
        });
      }
      return FakeResponse(200, const []);
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
        pushServiceProvider.overrideWithValue(FakePushService(token: 'fcm-1')),
        appVersionProvider.overrideWithValue('1.0.0+1'),
        pendingCaptureCountProvider.overrideWith(
          (ref) => Stream.value(pending),
        ),
        availableBoxCodesProvider.overrideWith((ref) => Stream.value(codes)),
        productTypesProvider(
          null,
        ).overrideWith((ref) => Stream.value(const [])),
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
          home: HomeView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('what cannot be lost goes first', () {
    testWidgets('captures waiting to be sent lead the screen', (tester) async {
      await pumpHome(tester, coordinator: false, pending: 2);

      expect(find.text('2 capturas pendientes de enviar'), findsOneWidget);
      expect(find.textContaining('Deja la aplicación abierta'), findsOneWidget);
    });

    testWidgets('one is written in singular', (tester) async {
      await pumpHome(tester, coordinator: false, pending: 1);

      expect(find.text('1 captura pendiente de enviar'), findsOneWidget);
    });

    testWidgets('an empty queue takes no room', (tester) async {
      await pumpHome(tester, coordinator: false);

      expect(find.textContaining('pendientes de enviar'), findsNothing);
    });
  });

  group('the two homes are different screens', () {
    testWidgets('coordination is shown what waits for a decision', (
      tester,
    ) async {
      await pumpHome(
        tester,
        coordinator: true,
        reviews: [riskReviewJson(status: 'PENDING')],
      );

      expect(find.text('1 revisión espera tu decisión'), findsOneWidget);
      // El aviso no dice por qué se levantó: eso se lee dentro.
      expect(find.textContaining('Volumen inusual'), findsNothing);
    });

    testWidgets('a resolved review no longer asks for anything', (
      tester,
    ) async {
      await pumpHome(
        tester,
        coordinator: true,
        reviews: [riskReviewJson(status: 'APPROVED')],
      );

      expect(find.textContaining('espera tu decisión'), findsNothing);
    });

    testWidgets('volunteering is not shown reviews it cannot resolve', (
      tester,
    ) async {
      await pumpHome(
        tester,
        coordinator: false,
        reviews: [riskReviewJson(status: 'PENDING')],
      );

      expect(find.textContaining('espera tu decisión'), findsNothing);
      expect(find.text('Tarimas abiertas'), findsNothing);
    });

    testWidgets('coordination gets pallets, volunteering does not', (
      tester,
    ) async {
      await pumpHome(tester, coordinator: true);

      expect(find.text('Tarimas abiertas'), findsOneWidget);
    });
  });

  group('working without signal', () {
    testWidgets('no reserved codes is said before it hurts', (tester) async {
      // Descubrir que no se puede sellar en el sótano es el peor momento.
      await pumpHome(tester, coordinator: false);

      expect(
        find.textContaining('Sin códigos de caja reservados'),
        findsOneWidget,
      );
    });

    testWidgets('the warning leads to where codes are reserved', (
      tester,
    ) async {
      // Reservar solo vivía dentro de pendientes, y esa pantalla solo se
      // ofrecía con la cola llena: la única puerta se abría cuando ya era
      // tarde. Decir «no vas a poder sellar» sin dar el camino es un reproche.
      await pumpHome(tester, coordinator: false);

      await tester.tap(find.textContaining('Sin códigos de caja reservados'));
      await tester.pumpAndSettle();

      expect(find.byType(PendingCapturesView), findsOneWidget);
    });

    testWidgets('with codes it says what is downloaded', (tester) async {
      await pumpHome(tester, coordinator: false, codes: 18);

      expect(
        find.textContaining('Listo para trabajar sin señal'),
        findsOneWidget,
      );
      expect(find.textContaining('18 códigos'), findsOneWidget);
    });
  });

  group('the weight says what it counts', () {
    testWidgets('sealed, not captured', (tester) async {
      // Quien prepare un envío con este número tiene que saber que lo capturado
      // sin sellar no pesa aquí.
      await pumpHome(tester, coordinator: true);

      expect(find.textContaining('kg sellados'), findsOneWidget);
      expect(find.textContaining('12 cajas'), findsOneWidget);
    });
  });
}
