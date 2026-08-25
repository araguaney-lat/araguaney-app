import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/catalog/ui/catalog_list_view.dart';
import 'package:araguaney_app/features/catalog/ui/missing_product_sheet.dart';
import 'package:araguaney_app/features/catalog/ui/product_record_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Map<String, Object?> gtinJson({
    String id = 'gtin-1',
    String gtin = '7591234567890',
  }) => {
    'id': id,
    'gtin': gtin,
    'source': 'capture',
    'created_at': testNow.toIso8601String(),
  };

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget home, {
    required FakeHttpAdapter adapter,
    bool national = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        appDatabaseProvider.overrideWithValue(db),
        isNationalAdminProvider.overrideWithValue(national),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('finding a product', () {
    testWidgets('the cached catalogue answers while typing', (tester) async {
      await db.catalogDao.replaceAll([productTypeRow()]);
      final adapter = OfflineHttpAdapter();

      await pump(tester, const CatalogListView(), adapter: adapter);
      await tester.enterText(find.byType(TextField), 'paracet');
      await tester.pumpAndSettle();

      expect(find.text('Paracetamol 500 mg'), findsOneWidget);
      // Nothing was asked of anybody: this has to work in a basement.
      expect(adapter.requests, isEmpty);
    });

    testWidgets('the server is asked only when somebody asks it', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [
          productTypeJson(id: 'pt-9', displayName: 'Ibuprofeno 400 mg'),
        ]),
      );

      await pump(tester, const CatalogListView(), adapter: adapter);
      await tester.enterText(find.byType(TextField), 'ibupro');
      await tester.pumpAndSettle();
      expect(adapter.requests, isEmpty);

      await tester.tap(find.text('Buscar en el servidor'));
      await tester.pumpAndSettle();

      expect(find.text('Ibuprofeno 400 mg'), findsOneWidget);
      expect(adapter.requests.single.path, '/v1/product-types/search');
    });

    testWidgets('a search the server cannot answer either says so', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((_) => const FakeResponse(200, []));

      await pump(tester, const CatalogListView(), adapter: adapter);
      await tester.enterText(find.byType(TextField), 'nada');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buscar en el servidor'));
      await tester.pumpAndSettle();

      expect(find.text('El servidor tampoco lo tiene.'), findsOneWidget);
    });

    testWidgets('only a national administration is offered the form', (
      tester,
    ) async {
      await pump(
        tester,
        const CatalogListView(),
        adapter: OfflineHttpAdapter(),
      );

      expect(find.text('Nuevo producto'), findsNothing);
    });
  });

  group('the record', () {
    FakeHttpAdapter recordAdapter({String? campaignId}) =>
        FakeHttpAdapter((options) {
          if (options.path.endsWith('/gtins')) {
            return FakeResponse(200, [gtinJson()]);
          }
          return FakeResponse(
            200,
            productTypeJson(id: 'pt-1', campaignId: campaignId),
          );
        });

    testWidgets('a campaign product is shown as a proposal', (tester) async {
      await pump(
        tester,
        const ProductRecordView(productId: 'pt-1'),
        adapter: recordAdapter(campaignId: 'campaign-1'),
        national: true,
      );

      expect(find.text('Propuesto'), findsOneWidget);
      expect(find.text('Aceptar en el catálogo'), findsOneWidget);
    });

    testWidgets('accepting is not offered to a centre session', (tester) async {
      await pump(
        tester,
        const ProductRecordView(productId: 'pt-1'),
        adapter: recordAdapter(campaignId: 'campaign-1'),
      );

      expect(find.text('Propuesto'), findsOneWidget);
      expect(find.text('Aceptar en el catálogo'), findsNothing);
    });

    testWidgets('its barcodes are listed, and only a role can unlink', (
      tester,
    ) async {
      await pump(
        tester,
        const ProductRecordView(productId: 'pt-1'),
        adapter: recordAdapter(),
      );

      expect(find.text('7591234567890'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('accepting asks first and calls promote', (tester) async {
      final adapter = recordAdapter(campaignId: 'campaign-1');

      await pump(
        tester,
        const ProductRecordView(productId: 'pt-1'),
        adapter: adapter,
        national: true,
      );
      await tester.tap(find.text('Aceptar en el catálogo'));
      await tester.pumpAndSettle();

      // The confirmation says what it does and does not do it yet.
      expect(find.text('Aceptar este producto'), findsOneWidget);
      expect(
        adapter.requests.where((r) => r.path.endsWith('/promote')),
        isEmpty,
      );

      await tester.tap(find.text('Aceptar en el catálogo').last);
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where((r) => r.path.endsWith('/promote')),
        hasLength(1),
      );
    });
  });

  group('when the catalogue does not have it', () {
    testWidgets('somebody who captures is offered to ask, not a form', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                MissingProductSheet.show(context, gtin: '7591234567890'),
            child: const Text('open'),
          ),
        ),
        adapter: OfflineHttpAdapter(),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // A form that answers 403 is not a way out.
      expect(find.text('Pedir que lo agreguen'), findsOneWidget);
      expect(find.text('Crear producto'), findsNothing);
    });

    testWidgets('a national administration is offered to create it', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                MissingProductSheet.show(context, gtin: '7591234567890'),
            child: const Text('open'),
          ),
        ),
        adapter: OfflineHttpAdapter(),
        national: true,
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Crear producto'), findsOneWidget);
      expect(find.textContaining('7591234567890'), findsOneWidget);
    });
  });
}
