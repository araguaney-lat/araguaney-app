import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('markFailed keeps the last successful synchronization', () async {
    await db.syncMarkersDao.markSynced(SyncResource.boxes, testNow);

    await db.syncMarkersDao.markFailed(SyncResource.boxes, 'NETWORK_ERROR');

    final marker = await db.syncMarkersDao.read(SyncResource.boxes);
    expect(marker?.lastSyncedAt, testNow);
    expect(marker?.lastFailureCode, 'NETWORK_ERROR');
  });

  test('markSynced clears the previous failure', () async {
    await db.syncMarkersDao.markFailed(SyncResource.boxes, 'NETWORK_ERROR');

    await db.syncMarkersDao.markSynced(SyncResource.boxes, testNow);

    final marker = await db.syncMarkersDao.read(SyncResource.boxes);
    expect(marker?.lastFailureCode, isNull);
    expect(marker?.lastSyncedAt, testNow);
  });

  test('markers are independent per resource', () async {
    await db.syncMarkersDao.markSynced(SyncResource.boxes, testNow);

    expect(await db.syncMarkersDao.read(SyncResource.productTypes), isNull);
  });
}
