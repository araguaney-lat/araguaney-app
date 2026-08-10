import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:araguaney_app/core/sync/sync_outcome.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  CatalogRepository repositoryOn(FakeHttpAdapter adapter) => CatalogRepository(
    api: ProductTypesApi(fakeDio(adapter)),
    database: db,
    now: () => testNow,
  );

  test('refresh replaces the local catalog with what the API served', () async {
    await db.catalogDao.replaceAll([productTypeRow(id: 'pt-stale')]);
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, [productTypeJson(id: 'pt-1')]),
    );

    final outcome = await repositoryOn(adapter).refresh();

    expect(outcome, isA<SyncSucceeded>());
    expect((await db.catalogDao.all()).map((row) => row.id), ['pt-1']);
  });

  test('refresh keeps the campaign visibility served by the API', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, [productTypeJson(campaignId: 'campaign-9')]),
    );

    await repositoryOn(adapter).refresh();

    expect((await db.catalogDao.findById('pt-1'))?.campaignId, 'campaign-9');
  });

  test('a successful refresh records when it happened', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const []));

    await repositoryOn(adapter).refresh();

    final marker = await db.syncMarkersDao.read(SyncResource.productTypes);
    expect(marker?.lastSyncedAt, testNow);
    expect(marker?.lastFailureCode, isNull);
  });

  test('a failed refresh leaves the cached catalog untouched', () async {
    await db.catalogDao.replaceAll([productTypeRow(id: 'pt-1')]);

    final outcome = await repositoryOn(OfflineHttpAdapter()).refresh();

    expect(outcome, isA<SyncFailed>());
    expect((outcome as SyncFailed).failure, isA<NetworkFailure>());
    expect((await db.catalogDao.all()).map((row) => row.id), ['pt-1']);
  });

  test('a failed refresh records the failure code', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'sin permiso'},
      }),
    );

    await repositoryOn(adapter).refresh();

    final marker = await db.syncMarkersDao.read(SyncResource.productTypes);
    expect(marker?.lastFailureCode, 'FORBIDDEN');
  });
}
