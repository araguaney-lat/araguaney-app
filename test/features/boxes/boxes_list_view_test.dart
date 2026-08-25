import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/boxes/data/boxes_providers.dart';
import 'package:araguaney_app/features/boxes/data/boxes_repository.dart';
import 'package:araguaney_app/features/boxes/ui/boxes_list_view.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
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
        writeCenterIdProvider.overrideWithValue(null),
        connectivityProbeProvider.overrideWithValue(probe),
        // La pantalla dispara el coordinador al abrirse, y este vacía la cola
        // de quien tenga sesión. Aquí no hay sesión: lo que se prueba es la
        // lista.
        currentUserIdProvider.overrideWithValue(null),
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
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BoxesListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders the cached boxes without any network', (tester) async {
    await db.catalogDao.replaceAll([productTypeRow()]);
    await db.boxesDao.replaceAll([boxRow(code: 'CJ-0007', status: 'SEALED')]);

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

  group('filtering by status', () {
    Future<void> pumpWithBoxes(WidgetTester tester) async {
      await db.boxesDao.replaceAll([
        boxRow(id: 'b1', code: 'BX-0001'),
        boxRow(id: 'b2', code: 'BX-0002', status: 'SEALED'),
        boxRow(id: 'b3', code: 'BX-0003', status: 'SEALED'),
      ]);
      await pumpList(tester);
    }

    testWidgets('the screen says how many boxes the center has', (
      tester,
    ) async {
      await pumpWithBoxes(tester);

      expect(find.text('3 cajas en el centro'), findsOneWidget);
    });

    testWidgets('each status carries its own count', (tester) async {
      // Ofrecer un filtro que deja la pantalla vacía sin avisar es peor que no
      // ofrecerlo.
      await pumpWithBoxes(tester);

      expect(find.text('Sin sellar · 1'), findsOneWidget);
      expect(find.text('Sellada · 2'), findsOneWidget);
    });

    testWidgets('choosing one leaves only its boxes', (tester) async {
      await pumpWithBoxes(tester);

      await tester.tap(find.text('Sellada · 2'));
      await tester.pumpAndSettle();

      expect(find.text('BX-0002'), findsOneWidget);
      expect(find.text('BX-0001'), findsNothing);
    });

    testWidgets('a status with nothing in it is not offered', (tester) async {
      await pumpWithBoxes(tester);

      expect(find.textContaining('Enviada'), findsNothing);
    });
  });

  group('sealing from the list', () {
    /// Con señal: el adaptador por defecto de estas pruebas no llega al
    /// servidor, y el coordinador lo reporta como sin conexión — que es
    /// precisamente cuando sellar no se ofrece.
    FakeHttpAdapter onlineWith(List<Map<String, Object?>> boxes) =>
        FakeHttpAdapter(
          (options) => FakeResponse(
            200,
            options.path.contains('boxes') ? boxes : const [],
          ),
        );

    testWidgets('only an open box offers it', (tester) async {
      await pumpList(
        tester,
        adapter: onlineWith([
          boxJson(id: 'b1', code: 'BX-0001'),
          boxJson(id: 'b2', code: 'BX-0002', status: 'SEALED'),
        ]),
      );

      expect(find.widgetWithText(TextButton, 'Sellar'), findsOneWidget);
    });

    testWidgets('offline it is not offered at all', (tester) async {
      // Sellar decide sobre estado compartido que puede estar cambiando en otro
      // dispositivo, así que exige conexión.
      await db.boxesDao.replaceAll([boxRow(id: 'b1', code: 'BX-0001')]);
      await pumpList(tester);

      expect(find.widgetWithText(TextButton, 'Sellar'), findsNothing);
      expect(find.text('Sin sellar'), findsOneWidget);
    });

    testWidgets('it asks first, and shows what is inside', (tester) async {
      // Desde la lista no se ve el contenido, y sellar es la frontera entre
      // «esto se corrige» y «esto ya viaja».
      await pumpList(
        tester,
        adapter: onlineWith([boxJson(id: 'b1', code: 'BX-0001')]),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Sellar'));
      await tester.pumpAndSettle();

      // La fila de atrás también dice el contenido; lo que importa es que el
      // diálogo lo repita, para decidir sin volver a la lista.
      expect(find.text('Sellar BX-0001'), findsOneWidget);
      expect(find.textContaining('10 unidad'), findsNWidgets(2));
      expect(find.textContaining('ya no admite cambios'), findsOneWidget);
    });

    testWidgets('cancelling seals nothing', (tester) async {
      await pumpList(
        tester,
        adapter: onlineWith([boxJson(id: 'b1', code: 'BX-0001')]),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Sellar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      final box = await db.boxesDao.findById('b1');
      expect(box!.status, 'DRAFT');
    });
  });
}
