import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/sync/sync_coordinator.dart';
import 'package:araguaney_app/features/boxes/data/boxes_providers.dart';
import 'package:araguaney_app/features/boxes/data/boxes_repository.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
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

  ProviderContainer containerWith(FakeHttpAdapter adapter) {
    final container = ProviderContainer(
      overrides: [
        connectivityProbeProvider.overrideWithValue(probe),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(
            api: ProductTypesApi(fakeDio(adapter)),
            database: db,
            now: () => testNow,
          ),
        ),
        boxesRepositoryProvider.overrideWithValue(
          BoxesRepository(
            api: BoxesApi(fakeDio(adapter)),
            database: db,
            now: () => testNow,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('refreshAll fills the cache from both resources', () async {
    final adapter = FakeHttpAdapter(
      (options) => options.path.contains('product-types')
          ? FakeResponse(200, [productTypeJson()])
          : FakeResponse(200, [boxJson()]),
    );
    final container = containerWith(adapter);

    await container.read(syncCoordinatorProvider).refreshAll();

    expect(await db.catalogDao.all(), hasLength(1));
    expect(await db.boxesDao.count(), 1);
  });

  test('a successful refresh proves the server is reachable', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const []));
    final container = containerWith(adapter);

    await container.read(syncCoordinatorProvider).refreshAll();

    expect(
      container.read(connectivityControllerProvider),
      ConnectivityStatus.online,
    );
  });

  test('only a network failure marks the device offline', () async {
    final container = containerWith(OfflineHttpAdapter());

    await container.read(syncCoordinatorProvider).refreshAll();

    expect(
      container.read(connectivityControllerProvider),
      ConnectivityStatus.offline,
    );
  });

  test('a server rejection still counts as reachable', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'sin permiso'},
      }),
    );
    final container = containerWith(adapter);

    await container.read(syncCoordinatorProvider).refreshAll();

    expect(
      container.read(connectivityControllerProvider),
      ConnectivityStatus.online,
    );
  });

  test('coming back from offline triggers one refresh', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const []));
    final container = containerWith(adapter);
    container.read(syncCoordinatorProvider);
    container.read(connectivityControllerProvider.notifier).reportUnreachable();

    probe.emit(hasInterface: true);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Un refresco por recurso: catálogo y cajas.
    expect(adapter.requests, hasLength(2));
  });

  test('a second refresh while one is running is not queued', () async {
    final adapter = FakeHttpAdapter(
      (_) =>
          FakeResponse(200, const [], delay: const Duration(milliseconds: 20)),
    );
    final container = containerWith(adapter);
    final coordinator = container.read(syncCoordinatorProvider);

    await Future.wait([coordinator.refreshAll(), coordinator.refreshAll()]);

    expect(adapter.requests, hasLength(2));
  });
}
