import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:araguaney_app/core/sync/sync_outcome.dart';
import 'package:araguaney_app/features/boxes/data/boxes_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

/// A page of [count] boxes with different codes, so the primary key does not
/// collide between pages.
List<Map<String, Object?>> boxPage(int count, {int from = 0}) => [
  for (var i = from; i < from + count; i++)
    boxJson(id: 'box-$i', code: 'CJ-$i'),
];

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  BoxesRepository repositoryOn(FakeHttpAdapter adapter) => BoxesRepository(
    api: BoxesApi(fakeDio(adapter)),
    database: db,
    now: () => testNow,
  );

  test('refresh stops paging on a short page', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, boxPage(5)));

    final outcome = await repositoryOn(adapter).refresh();

    expect(adapter.requests, hasLength(1));
    expect((outcome as SyncSucceeded).itemCount, 5);
    expect(await db.boxesDao.count(), 5);
  });

  test('refresh stops at the window limit', () async {
    var served = 0;
    final adapter = FakeHttpAdapter((_) {
      final page = boxPage(BoxesRepository.pageSize, from: served);
      served += BoxesRepository.pageSize;
      return FakeResponse(200, page);
    });

    await repositoryOn(adapter).refresh();

    // 200 + 200 + 200 = 600 fetched, 500 stored: the window does not grow with
    // whatever extra the last page brings.
    expect(adapter.requests, hasLength(3));
    expect(await db.boxesDao.count(), BoxesRepository.windowLimit);
  });

  test('refresh advances the offset between pages', () async {
    var served = 0;
    final adapter = FakeHttpAdapter((_) {
      final page = served == 0
          ? boxPage(BoxesRepository.pageSize)
          : boxPage(1, from: BoxesRepository.pageSize);
      served += page.length;
      return FakeResponse(200, page);
    });

    await repositoryOn(adapter).refresh();

    final offsets = adapter.requests
        .map((request) => request.queryParameters['offset'])
        .toList();
    expect(offsets, [0, BoxesRepository.pageSize]);
  });

  test('a failed refresh keeps the cached window and records why', () async {
    await db.boxesDao.replaceAll([boxRow(id: 'box-cached')]);

    final outcome = await repositoryOn(OfflineHttpAdapter()).refresh();

    expect((outcome as SyncFailed).isNetworkFailure, isTrue);
    expect(await db.boxesDao.count(), 1);
    final marker = await db.syncMarkersDao.read(SyncResource.boxes);
    expect(marker?.lastFailureCode, 'NETWORK_ERROR');
  });

  test('a server rejection is not reported as a network failure', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'sin permiso'},
      }),
    );

    final outcome = await repositoryOn(adapter).refresh();

    expect((outcome as SyncFailed).isNetworkFailure, isFalse);
  });

  test('refreshBox caches a box fetched outside the window', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, boxJson(id: 'box-far', code: 'CJ-9999')),
    );

    final outcome = await repositoryOn(adapter).refreshBox('box-far');

    expect(outcome, isA<SyncSucceeded>());
    expect((await db.boxesDao.findById('box-far'))?.code, 'CJ-9999');
  });

  test('watchBoxes reads from the cache without touching the API', () async {
    await db.catalogDao.replaceAll([productTypeRow()]);
    await db.boxesDao.replaceAll([boxRow()]);
    final adapter = FakeHttpAdapter((_) => FakeResponse(500, const {}));

    final rows = await repositoryOn(adapter).watchBoxes().first;

    expect(rows.single.productName, 'Paracetamol 500 mg');
    expect(adapter.requests, isEmpty);
  });
}
