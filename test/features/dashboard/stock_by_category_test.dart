import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/dashboard_api.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/ui/category_label.dart';
import 'package:araguaney_app/features/dashboard/data/center_dashboard_repository.dart';
import 'package:araguaney_app/features/dashboard/ui/stock_by_category_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/l10n.dart';

void main() {
  Map<String, Object?> aggregatesJson({
    List<Map<String, Object?>>? categories,
  }) => {
    'by_category':
        categories ??
        [
          {'category': 'MEDICINE', 'box_count': 12, 'total_units': 480},
        ],
    'by_center': const [],
    'by_inn': const [],
    'totals': {
      'active_centers': 1,
      'total_boxes_sealed': 12,
      'total_intakes': 30,
      'total_shipments_sent': 2,
      'total_units_sealed': 480,
      'total_weight_kg': 86.4,
    },
  };

  group('asking the server', () {
    test('nothing about the center travels in the request', () async {
      // El endpoint se llama «national» y no lo es: el servidor lo acota con
      // `tenant_scope`. Si el cliente mandara un centro, existiría la pregunta
      // de qué pasa cuando manda otro.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, aggregatesJson()),
      );

      await CenterDashboardRepository(
        DashboardApi(fakeDio(adapter)),
      ).aggregates();

      final request = adapter.requests.single;
      expect(request.path, '/v1/dashboard/national');
      expect(request.queryParameters, isEmpty);
    });
  });

  group('on screen', () {
    Future<void> pumpView(
      WidgetTester tester, {
      List<Map<String, Object?>>? categories,
      bool national = false,
      int status = 200,
    }) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(
          status,
          status == 200
              ? aggregatesJson(categories: categories)
              : {
                  'error': {'code': 'FORBIDDEN', 'message': 'no'},
                },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          isNationalAdminProvider.overrideWithValue(national),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StockByCategoryView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sealed boxes are counted by category', (tester) async {
      await pumpView(tester);

      expect(find.text('Medicamentos'), findsOneWidget);
      expect(find.text('12 cajas'), findsOneWidget);
      expect(find.text('480'), findsOneWidget);
    });

    testWidgets('the screen says a box counts from sealing', (tester) async {
      // La pantalla anterior contaba lo capturado y por eso no podía llamarse
      // stock. Esta puede, y dice desde cuándo cuenta una caja.
      await pumpView(tester);

      expect(
        find.textContaining('Cajas selladas de este centro'),
        findsOneWidget,
      );
    });

    testWidgets('national administration is told the numbers are everyones', (
      tester,
    ) async {
      // El mismo endpoint responde una cosa u otra según el rol; callarlo haría
      // que alguien leyera el país como si fuera su centro.
      await pumpView(tester, national: true);

      expect(
        find.textContaining('Cajas selladas de todos los centros'),
        findsOneWidget,
      );
    });

    testWidgets('nothing sealed says so and explains when a box counts', (
      tester,
    ) async {
      await pumpView(tester, categories: const []);

      expect(find.textContaining('No hay cajas selladas'), findsOneWidget);
    });

    testWidgets('a refusal is shown with the words the policy allows', (
      tester,
    ) async {
      await pumpView(tester, status: 403);

      expect(
        find.text('No tienes permiso para hacer esta operación.'),
        findsOneWidget,
      );
    });
  });

  group('reading a category', () {
    test('the eight keys read in Spanish', () async {
      final l10n = await spanish();
      expect(categoryLabel(l10n, 'MEDICINE'), 'Medicamentos');
      expect(categoryLabel(l10n, 'RESCUE_GEAR'), 'Equipo de rescate');
      expect(categoryLabel(l10n, 'OTHER'), 'Otros');
    });

    test('one this version does not know still renders', () async {
      final l10n = await spanish();
      expect(categoryLabel(l10n, 'PROSTHETICS'), 'PROSTHETICS');
    });
  });
}
