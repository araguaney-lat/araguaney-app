import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/sync/sync_outcome.dart';
import 'package:araguaney_app/features/intake/data/box_code_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  BoxCodeRepository repositoryOn(FakeHttpAdapter adapter) => BoxCodeRepository(
    api: BoxesApi(fakeDio(adapter)),
    database: db,
    now: () => testNow,
  );

  test('a reserved block is stored for the person who asked for it', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(201, {
        'codes': ['BX-A', 'BX-B'],
        'available': 2,
      }),
    );

    final outcome = await repositoryOn(
      adapter,
    ).topUp(count: 2, userId: 'user-1');

    expect(outcome, isA<SyncSucceeded>());
    expect(await db.boxCodesDao.available('user-1'), 2);
    expect(await db.boxCodesDao.available('user-2'), 0);
  });

  test('a code is never handed out twice', () async {
    // Dos cajas con la misma etiqueta son dos bultos que el manifiesto declara
    // como uno.
    await db.boxCodesDao.store(
      ['BX-A', 'BX-B', 'BX-C'],
      userId: 'user-1',
      at: testNow,
    );
    final repository = repositoryOn(
      FakeHttpAdapter((_) => FakeResponse(500, const {})),
    );

    final first = await repository.take(2, userId: 'user-1');
    final second = await repository.take(2, userId: 'user-1');

    expect(first.toSet().intersection(second.toSet()), isEmpty);
    expect({...first, ...second}, hasLength(3));
  });

  test('running out returns fewer codes rather than failing', () async {
    // Quedarse sin códigos no puede impedir capturar: perder la captura sería
    // mucho peor que quedarse sin etiqueta.
    await db.boxCodesDao.store(['BX-A'], userId: 'user-1', at: testNow);

    final taken = await repositoryOn(
      FakeHttpAdapter((_) => FakeResponse(500, const {})),
    ).take(3, userId: 'user-1');

    expect(taken, ['BX-A']);
  });

  test('one persons block is not spent by another', () async {
    await db.boxCodesDao.store(['BX-A'], userId: 'user-1', at: testNow);

    final taken = await repositoryOn(
      FakeHttpAdapter((_) => FakeResponse(500, const {})),
    ).take(1, userId: 'user-2');

    expect(taken, isEmpty);
    expect(await db.boxCodesDao.available('user-1'), 1);
  });

  test('a rejected top-up keeps the reason and changes nothing', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(422, {
        'error': {'code': 'INVALID_COUNT', 'message': 'Cantidad no válida'},
      }),
    );

    final outcome = await repositoryOn(
      adapter,
    ).topUp(count: 99999, userId: 'user-1');

    expect(
      (outcome as SyncFailed).failure.operatorMessage,
      'Cantidad no válida',
    );
    expect(await db.boxCodesDao.available('user-1'), 0);
  });
}
