import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/api/generated/models/product_type_create.dart';
import 'package:araguaney_app/core/api/generated/models/product_type_update.dart';
import 'package:araguaney_app/core/db/app_database.dart';
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

  CatalogRepository repositoryFor(FakeHttpAdapter adapter) => CatalogRepository(
    api: ProductTypesApi(fakeDio(adapter)),
    database: db,
    now: () => testNow,
  );

  group('searching beyond what is cached', () {
    test('the query travels and the answer becomes rows', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [
          productTypeJson(id: 'pt-9', displayName: 'Ibuprofeno 400 mg'),
        ]),
      );

      final outcome = await repositoryFor(adapter).search('ibupro');

      expect(adapter.requests.single.path, '/v1/product-types/search');
      expect(adapter.requests.single.queryParameters['q'], 'ibupro');
      expect(outcome, isA<CatalogDone<List<ProductTypeRow>>>());
      final rows = (outcome as CatalogDone<List<ProductTypeRow>>).value;
      expect(rows.single.displayName, 'Ibuprofeno 400 mg');
    });

    test(
      'a search that does not reach the server is refused, not thrown',
      () async {
        final outcome = await repositoryFor(
          OfflineHttpAdapter(),
        ).search('para');

        expect(outcome, isA<CatalogRefused<List<ProductTypeRow>>>());
      },
    );
  });

  group('creating', () {
    test('what the server confirms is usable for capture right away', () async {
      // A product is created while somebody is holding it, and the next thing
      // they do is capture it. Waiting for the next sync would mean creating
      // it and still not being able to use it.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(201, productTypeJson(id: 'pt-new')),
      );

      await repositoryFor(adapter).create(
        const ProductTypeCreate(
          displayName: 'Suero oral',
          category: 'MEDICINE',
        ),
      );

      expect(await db.catalogDao.findById('pt-new'), isNotNull);
    });

    test('a refusal leaves the local catalogue untouched', () async {
      await db.catalogDao.replaceAll([productTypeRow()]);
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(403, {
          'error': {'code': 'FORBIDDEN', 'message': 'National admin required'},
        }),
      );

      final outcome = await repositoryFor(adapter).create(
        const ProductTypeCreate(
          displayName: 'Suero oral',
          category: 'MEDICINE',
        ),
      );

      expect((outcome as CatalogRefused).isForbidden, isTrue);
      expect(await db.catalogDao.all(), hasLength(1));
    });
  });

  group('promoting', () {
    test('it is its own call, and the cache learns the new tier', () async {
      await db.catalogDao.replaceAll([
        productTypeRow(id: 'pt-1', campaignId: 'campaign-1'),
      ]);
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, productTypeJson(id: 'pt-1')),
      );

      await repositoryFor(adapter).promote('pt-1');

      expect(adapter.requests.single.path, '/v1/product-types/pt-1/promote');
      // The server promotes by clearing the campaign, so the cached row has to
      // stop belonging to one too.
      expect((await db.catalogDao.findById('pt-1'))?.campaignId, isNull);
    });
  });

  group('correcting a barcode', () {
    test('unlinking asks the server to undo the relationship', () async {
      final adapter = FakeHttpAdapter((_) => const FakeResponse(204, null));

      final outcome = await repositoryFor(
        adapter,
      ).unlinkGtin(productId: 'pt-1', gtinId: 'gtin-7');

      expect(outcome, isA<CatalogDone<void>>());
      expect(adapter.requests.single.method, 'DELETE');
      expect(
        adapter.requests.single.path,
        '/v1/product-types/pt-1/gtins/gtin-7',
      );
    });
  });

  group('editing', () {
    test('only what the form filled in travels', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, productTypeJson(id: 'pt-1')),
      );

      await repositoryFor(adapter).update(
        'pt-1',
        const ProductTypeUpdate(displayName: 'Paracetamol 650 mg'),
      );

      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['display_name'], 'Paracetamol 650 mg');
      expect(adapter.requests.single.method, 'PATCH');
    });
  });
}
