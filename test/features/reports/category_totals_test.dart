import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/reports_api.dart';
import 'package:araguaney_app/core/api/generated/models/campaign_out.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/reports/data/reports_repository.dart';
import 'package:araguaney_app/features/reports/ui/category_totals_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Map<String, Object?> categoryJson({
    String category = 'MEDICINE',
    int boxCount = 12,
    int unitCount = 480,
  }) => {'category': category, 'box_count': boxCount, 'unit_count': unitCount};

  group('asking the server', () {
    test('no center travels in the request', () async {
      // El alcance lo pone el servidor con `tenant_scope`. Si el cliente
      // mandara un centro, existiría la pregunta de qué pasa cuando manda otro.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [categoryJson()]),
      );

      await ReportsRepository(
        ReportsApi(fakeDio(adapter)),
      ).byCategory('campaign-1');

      final request = adapter.requests.single;
      expect(request.path, contains('/campaign/campaign-1/by-category'));
      expect(request.queryParameters, isEmpty);
      expect(request.data, isNull);
    });

    test('the totals come back as the server sent them', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [
          categoryJson(),
          categoryJson(category: 'HYGIENE', boxCount: 3, unitCount: 60),
        ]),
      );

      final rows = await ReportsRepository(
        ReportsApi(fakeDio(adapter)),
      ).byCategory('campaign-1');

      expect(rows.map((r) => r.category), ['MEDICINE', 'HYGIENE']);
      expect(rows.last.unitCount, 60);
    });
  });

  group('reading a category', () {
    test('the known ones read in Spanish', () {
      expect(categoryLabel('MEDICINE'), 'Medicamentos');
      expect(categoryLabel('MEDICAL_SUPPLY'), 'Insumo médico');
      expect(categoryLabel('RESCUE_GEAR'), 'Equipo de rescate');
    });

    test('one this version does not know is shown anyway', () {
      // El catálogo puede crecer; una fila entera no puede desaparecer porque
      // el teléfono sea viejo.
      expect(categoryLabel('PROSTHETICS'), 'PROSTHETICS');
    });
  });

  group('on screen', () {
    Future<void> pumpView(
      WidgetTester tester, {
      List<Map<String, Object?>>? rows,
      List<CampaignOut>? campaigns,
      int status = 200,
    }) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(
          status,
          status == 200
              ? (rows ?? [categoryJson()])
              : {
                  'error': {'code': 'FORBIDDEN', 'message': 'no'},
                },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          myCampaignsProvider.overrideWith(
            (ref) async => campaigns ?? [campaign()],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CategoryTotalsView()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the first campaign is chosen so something is visible', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('Campaña de invierno'), findsOneWidget);
      expect(find.text('Medicamentos'), findsOneWidget);
      expect(find.text('480'), findsOneWidget);
    });

    testWidgets('the screen says what the number is not', (tester) async {
      // Llamarlo stock sería cómodo y falso: lo despachado sigue contando, y
      // alguien repondría inventario con este número.
      await pumpView(tester);

      expect(find.textContaining('últimos 30 días'), findsOneWidget);
      expect(find.textContaining('no es lo que hay en bodega'), findsOneWidget);
      expect(find.textContaining('Stock'), findsNothing);
    });

    testWidgets('nothing captured says so instead of showing an empty list', (
      tester,
    ) async {
      await pumpView(tester, rows: const []);

      expect(find.textContaining('no capturó nada'), findsOneWidget);
    });

    testWidgets('somebody in no campaign is told why there is nothing', (
      tester,
    ) async {
      await pumpView(tester, campaigns: const []);

      expect(
        find.textContaining('No participas en ninguna campaña'),
        findsOneWidget,
      );
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
}
