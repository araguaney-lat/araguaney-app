import 'package:araguaney_app/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  group('a block belongs to a centre', () {
    test('codes reserved for one centre are not spent in another', () async {
      await db.boxCodesDao.store(
        ['BX-A'],
        userId: 'user-1',
        centerId: 'center-1',
        at: testNow,
      );

      // The server hands out codes for a centre. Spending them elsewhere puts
      // the wrong centre's label on a physical box, and the label is stuck on
      // before anybody notices.
      expect(
        await db.boxCodesDao.take(
          1,
          userId: 'user-1',
          centerId: 'center-2',
          at: testNow,
        ),
        isEmpty,
      );
      expect(await db.boxCodesDao.available('user-1', centerId: 'center-1'), 1);
    });

    test('they are spent where they were reserved', () async {
      await db.boxCodesDao.store(
        ['BX-A'],
        userId: 'user-1',
        centerId: 'center-1',
        at: testNow,
      );

      expect(
        await db.boxCodesDao.take(
          1,
          userId: 'user-1',
          centerId: 'center-1',
          at: testNow,
        ),
        ['BX-A'],
      );
    });

    test('a block from before this column is still spendable', () async {
      // Reserving has always required belonging to a centre, so a row without
      // one can only belong to somebody who had exactly one. Stranding those
      // codes would empty a coordinator's block on upgrade.
      await db.boxCodesDao.store(['BX-OLD'], userId: 'user-1', at: testNow);

      expect(
        await db.boxCodesDao.take(
          1,
          userId: 'user-1',
          centerId: 'center-1',
          at: testNow,
        ),
        ['BX-OLD'],
      );
    });

    test('with no working centre the whole block counts', () async {
      await db.boxCodesDao.store(
        ['BX-A', 'BX-B'],
        userId: 'user-1',
        at: testNow,
      );

      expect(await db.boxCodesDao.available('user-1'), 2);
    });

    test('the block is still one person at a time', () async {
      await db.boxCodesDao.store(
        ['BX-A'],
        userId: 'user-1',
        centerId: 'center-1',
        at: testNow,
      );

      expect(
        await db.boxCodesDao.take(
          1,
          userId: 'user-2',
          centerId: 'center-1',
          at: testNow,
        ),
        isEmpty,
      );
    });
  });
}
