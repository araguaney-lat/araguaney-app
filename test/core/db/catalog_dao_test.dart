import 'package:araguaney_app/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('replaceAll drops product types the server stopped serving', () async {
    await db.catalogDao.replaceAll([
      productTypeRow(id: 'pt-1'),
      productTypeRow(id: 'pt-2', displayName: 'Ibuprofeno 400 mg'),
    ]);

    await db.catalogDao.replaceAll([productTypeRow(id: 'pt-2')]);

    final ids = (await db.catalogDao.all()).map((row) => row.id);
    expect(ids, ['pt-2']);
  });

  test('replaceAll keeps the campaign visibility served by the API', () async {
    await db.catalogDao.replaceAll([
      productTypeRow(id: 'pt-1', campaignId: 'campaign-9'),
      productTypeRow(id: 'pt-2'),
    ]);

    final rows = await db.catalogDao.all();
    expect(rows.singleWhere((r) => r.id == 'pt-1').campaignId, 'campaign-9');
    expect(rows.singleWhere((r) => r.id == 'pt-2').campaignId, isNull);
  });

  test('a failed replaceAll leaves the previous catalog intact', () async {
    await db.catalogDao.replaceAll([productTypeRow(id: 'pt-1')]);

    // Two rows with the same primary key: the whole transaction blows up.
    await expectLater(
      db.catalogDao.replaceAll([
        productTypeRow(id: 'pt-2'),
        productTypeRow(id: 'pt-2'),
      ]),
      throwsA(anything),
    );

    final ids = (await db.catalogDao.all()).map((row) => row.id);
    expect(ids, ['pt-1']);
  });

  test('watchAll filters by category and sorts by display name', () async {
    await db.catalogDao.replaceAll([
      productTypeRow(
        id: 'pt-1',
        displayName: 'Zinc',
        category: 'MEDICAL_SUPPLY',
      ),
      productTypeRow(
        id: 'pt-2',
        displayName: 'Alcohol',
        category: 'MEDICAL_SUPPLY',
      ),
      productTypeRow(id: 'pt-3', displayName: 'Amoxicilina'),
    ]);

    final rows = await db.catalogDao.watchAll(category: 'MEDICAL_SUPPLY').first;

    expect(rows.map((row) => row.displayName), ['Alcohol', 'Zinc']);
  });
}
