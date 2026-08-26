import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/sync/sync_coordinator.dart';
import 'package:araguaney_app/features/boxes/data/boxes_providers.dart';
import 'package:araguaney_app/features/boxes/data/boxes_repository.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_sync.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/intake/domain/box_draft_input.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';
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

  ProviderContainer containerWith(FakeHttpAdapter adapter, {String? userId}) {
    final container = ProviderContainer(
      overrides: [
        connectivityProbeProvider.overrideWithValue(probe),
        // With no session there is no queue to flush, which is the case in most
        // of these tests: what is being measured is the refresh.
        currentUserIdProvider.overrideWithValue(userId),
        captureQueueSyncProvider.overrideWithValue(
          CaptureQueueSync(
            api: IntakesApi(fakeDio(adapter)),
            database: db,
            now: () => testNow,
          ),
        ),
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

    // One refresh per resource: catalogue and boxes.
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

  test('a session with pending captures empties its queue too', () async {
    await CaptureQueueRepository(database: db, now: () => testNow).enqueue(
      draft: const IntakeDraft(captureId: 'capture-1').addBox(
        BoxDraftInput(
          productType: productTypeRow(),
          quantity: 1,
          unit: 'unidad',
        ),
      ),
      userId: 'user-1',
    );
    final adapter = FakeHttpAdapter(
      (options) => options.path.contains('intakes')
          ? FakeResponse(201, intakeJson())
          : FakeResponse(200, const []),
    );
    final container = containerWith(adapter, userId: 'user-1');

    await container.read(syncCoordinatorProvider).refreshAll();

    expect(await db.captureQueueDao.pending('user-1'), isEmpty);
  });
}
