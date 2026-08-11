import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:araguaney_app/features/boxes/data/boxes_providers.dart';
import 'package:araguaney_app/features/boxes/data/boxes_repository.dart';
import 'package:araguaney_app/features/boxes/ui/boxes_list_view.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_connectivity.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeConnectivityProbe probe;

  setUp(() {
    db = openTestDatabase();
    probe = FakeConnectivityProbe();
  });

  tearDown(() async {
    await db.close();
    await probe.dispose();
  });

  Future<ProviderContainer> pumpList(
    WidgetTester tester, {
    FakeHttpAdapter? adapter,
  }) async {
    final http = adapter ?? OfflineHttpAdapter();
    final container = ProviderContainer(
      overrides: [
        connectivityProbeProvider.overrideWithValue(probe),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(
            api: ProductTypesApi(fakeDio(http)),
            database: db,
            now: () => testNow,
          ),
        ),
        boxesRepositoryProvider.overrideWithValue(
          BoxesRepository(
            api: BoxesApi(fakeDio(http)),
            database: db,
            now: () => testNow,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BoxesListView()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the cached boxes without any network', (tester) async {
    await db.catalogDao.replaceAll([productTypeRow()]);
    await db.boxesDao.replaceAll([boxRow(code: 'CJ-0007', status: 'sealed')]);

    await pumpList(tester);

    expect(find.text('CJ-0007'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg · 10 unidad'), findsOneWidget);
    expect(find.text('Sellada'), findsOneWidget);
  });

  testWidgets('a box whose product is not cached still shows its code', (
    tester,
  ) async {
    await db.boxesDao.replaceAll([boxRow(productTypeId: 'pt-missing')]);

    await pumpList(tester);

    expect(find.text('CJ-0001'), findsOneWidget);
    expect(find.textContaining('Producto no descargado'), findsOneWidget);
  });

  testWidgets('offline it says how old the cached list is', (tester) async {
    await db.boxesDao.replaceAll([boxRow()]);
    await db.syncMarkersDao.markSynced(
      SyncResource.boxes,
      DateTime.now().subtract(const Duration(minutes: 12)),
    );

    await pumpList(tester);

    // El refresco de apertura falla sin red, y el aviso aparece con la
    // antigüedad de lo que sí hay.
    expect(find.textContaining('Sin conexión · datos de hace'), findsOneWidget);
  });

  testWidgets('offline and empty it explains what a first sync is for', (
    tester,
  ) async {
    await pumpList(tester);

    expect(
      find.textContaining('Sin conexión y sin cajas descargadas'),
      findsOneWidget,
    );
  });

  testWidgets('with signal and no boxes it says the center has none', (
    tester,
  ) async {
    await pumpList(
      tester,
      adapter: FakeHttpAdapter((_) => FakeResponse(200, const [])),
    );

    expect(
      find.text('Este centro todavía no tiene cajas registradas.'),
      findsOneWidget,
    );
  });

  testWidgets('opening the screen refreshes what it shows', (tester) async {
    await db.boxesDao.replaceAll([boxRow(id: 'box-stale', code: 'CJ-VIEJA')]);
    final adapter = FakeHttpAdapter(
      (options) => options.path.contains('product-types')
          ? FakeResponse(200, const [])
          : FakeResponse(200, [boxJson(id: 'box-fresh', code: 'CJ-NUEVA')]),
    );

    await pumpList(tester, adapter: adapter);

    expect(find.text('CJ-NUEVA'), findsOneWidget);
    expect(find.text('CJ-VIEJA'), findsNothing);
  });

  testWidgets('tapping a box opens its record', (tester) async {
    await db.catalogDao.replaceAll([productTypeRow()]);
    await db.boxesDao.replaceAll([boxRow(code: 'CJ-0007')]);

    await pumpList(tester);
    await tester.tap(find.text('CJ-0007'));
    await tester.pumpAndSettle();

    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Cantidad'), findsOneWidget);
  });
}
