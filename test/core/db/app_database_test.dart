import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('opens at schema version 2', () {
    expect(db.schemaVersion, 2);
  });

  test(
    'the offline queue and the reserved codes are usable from the start',
    () async {
      // Llegaron en la versión 2 del esquema; que existan aquí comprueba que la
      // creación desde cero las incluye, no solo la migración.
      await db.boxCodesDao.store(['BX-A'], userId: 'user-1', at: testNow);

      expect(await db.boxCodesDao.available('user-1'), 1);
      expect(await db.captureQueueDao.pending('user-1'), isEmpty);
    },
  );

  test('clearReadModel empties every cached table', () async {
    await db.catalogDao.replaceAll([productTypeRow()]);
    await db.boxesDao.replaceAll([boxRow()]);
    await db.syncMarkersDao.markSynced(SyncResource.boxes, testNow);

    await db.clearReadModel();

    expect(await db.catalogDao.all(), isEmpty);
    expect(await db.boxesDao.count(), 0);
    expect(await db.syncMarkersDao.read(SyncResource.boxes), isNull);
  });
}
