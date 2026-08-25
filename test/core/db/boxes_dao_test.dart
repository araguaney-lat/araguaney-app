import 'package:araguaney_app/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('watchAll resolves the product name and sorts newest first', () async {
    await db.catalogDao.replaceAll([
      productTypeRow(id: 'pt-1', displayName: 'Paracetamol 500 mg'),
    ]);
    await db.boxesDao.replaceAll([
      boxRow(
        id: 'box-old',
        code: 'CJ-0001',
        createdAt: testNow.subtract(const Duration(days: 2)),
      ),
      boxRow(id: 'box-new', code: 'CJ-0002', createdAt: testNow),
    ]);

    final rows = await db.boxesDao.watchAll().first;

    expect(rows.map((row) => row.box.code), ['CJ-0002', 'CJ-0001']);
    expect(rows.first.productName, 'Paracetamol 500 mg');
  });

  test('watchAll narrows to the working centre when there is one', () async {
    // The cache holds whatever the server served, and a national session is
    // served every centre. A list of boxes that are somewhere else cannot be
    // checked against the shelf in front of anybody.
    await db.boxesDao.replaceAll([
      boxRow(id: 'box-here', code: 'CJ-0001', centerId: 'center-1'),
      boxRow(id: 'box-elsewhere', code: 'CJ-0002', centerId: 'center-2'),
    ]);

    final rows = await db.boxesDao.watchAll(centerId: 'center-1').first;

    expect(rows.map((row) => row.box.code), ['CJ-0001']);
  });

  test('a box whose product type is not cached still lists', () async {
    await db.boxesDao.replaceAll([boxRow(productTypeId: 'pt-missing')]);

    final rows = await db.boxesDao.watchAll().first;

    expect(rows, hasLength(1));
    expect(rows.single.productName, isNull);
  });

  test('upsert stores a box fetched outside the cached window', () async {
    await db.boxesDao.replaceAll([boxRow(id: 'box-1')]);

    await db.boxesDao.upsert(boxRow(id: 'box-2', code: 'CJ-0099'));

    expect(await db.boxesDao.count(), 2);
    expect((await db.boxesDao.findById('box-2'))?.code, 'CJ-0099');
  });

  test('upsert overwrites the cached copy of the same box', () async {
    await db.boxesDao.replaceAll([boxRow(status: 'DRAFT')]);

    await db.boxesDao.upsert(boxRow(status: 'SEALED'));

    expect(await db.boxesDao.count(), 1);
    expect((await db.boxesDao.findById('box-1'))?.status, 'SEALED');
  });
}
