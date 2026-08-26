import 'package:araguaney_app/core/api/generated/clients/catalog_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/features/catalog/data/barcode_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  BarcodeLookup lookupOn(FakeHttpAdapter adapter) =>
      BarcodeLookup(api: CatalogApi(fakeDio(adapter)), database: db);

  /// An adapter that answers 404 to everything. What is checked with it is not
  /// the answer but that its list of requests stays empty.
  FakeHttpAdapter unusedServer() => FakeHttpAdapter(
    (_) => FakeResponse(404, {
      'error': {'code': 'BARCODE_NOT_FOUND', 'message': 'no'},
    }),
  );

  test('a downloaded product resolves with no request at all', () async {
    // It is the case that matters: capturing happens where there is no signal.
    await db.catalogDao.replaceAll([
      productTypeRow(id: 'pt-1', gtin: '7501358142600'),
    ]);
    final adapter = unusedServer();

    final outcome = await lookupOn(adapter).byGtin('7501358142600');

    expect(outcome, isA<BarcodeProductFound>());
    final found = outcome as BarcodeProductFound;
    expect(found.product.id, 'pt-1');
    expect(found.fromCache, isTrue);
    expect(adapter.requests, isEmpty);
  });

  test('a UPC-E is expanded before it is asked about', () async {
    // The server would refuse the eight compressed digits: their check digit
    // was computed over the twelve-digit UPC-A.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {
        'source': 'local',
        'product_type': productTypeJson(id: 'pt-usa'),
      }),
    );

    await lookupOn(adapter).byGtin('01234505', compressed: true);

    expect(adapter.requests.single.path, contains('012000003455'));
  });

  test('a product the platform knows but the device does not is usable', () {
    // The device's catalogue may be old or have another campaign's visibility.
    // The server answers for it.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {
        'source': 'local',
        'product_type': productTypeJson(id: 'pt-9', displayName: 'Suero oral'),
      }),
    );

    return expectLater(
      lookupOn(adapter).byGtin('7501358142600'),
      completion(
        isA<BarcodeProductFound>()
            .having((o) => o.product.displayName, 'name', 'Suero oral')
            .having((o) => o.fromCache, 'fromCache', isFalse),
      ),
    );
  });

  test('what only Open Food Facts knows is described, never selected', () {
    // Adding a product type is the server's business. A client that invents one
    // puts inventory under a name the platform did not accept.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, {
        'source': 'open_food_facts',
        'prefill': {
          'gtin': '7501358142600',
          'display_name': 'Galletas de avena',
          'category': 'FOOD',
          'brand': 'Marca',
        },
      }),
    );

    return expectLater(
      lookupOn(adapter).byGtin('7501358142600'),
      completion(
        isA<BarcodeOnlyDescribed>().having(
          (o) => o.prefill.displayName,
          'displayName',
          'Galletas de avena',
        ),
      ),
    );
  });

  test('a code nobody knows says so with the server reason', () {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(404, {
        'error': {'code': 'BARCODE_NOT_FOUND', 'message': 'Barcode not found'},
      }),
    );

    return expectLater(
      lookupOn(adapter).byGtin('7501358142600'),
      completion(isA<BarcodeUnresolved>()),
    );
  });

  test('a QR payload with no digits is refused before any request', () async {
    final adapter = unusedServer();

    final outcome = await lookupOn(
      adapter,
    ).byGtin('https://nartex.example/simplex');

    expect(outcome, isA<BarcodeUnresolved>());
    expect(adapter.requests, isEmpty);
  });
}
