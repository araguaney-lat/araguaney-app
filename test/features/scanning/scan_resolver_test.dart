import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/donations_api.dart';
import 'package:araguaney_app/core/api/generated/clients/pallets_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/features/scanning/data/scan_resolution.dart';
import 'package:araguaney_app/features/scanning/data/scan_resolver.dart';
import 'package:araguaney_app/features/scanning/domain/scanned_code.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  ScanResolver resolverOn(FakeHttpAdapter adapter) {
    final dio = fakeDio(adapter);
    return ScanResolver(
      boxes: BoxesApi(dio),
      pallets: PalletsApi(dio),
      donations: DonationsApi(dio),
      database: db,
    );
  }

  group('a box code', () {
    test('resolves from the cache with no request at all', () async {
      await db.boxesDao.replaceAll([boxRow(code: 'BX-CACHED')]);
      final adapter = FakeHttpAdapter((_) => FakeResponse(500, const {}));

      final result = await resolverOn(
        adapter,
      ).resolve(const BoxCode('BX-CACHED'));

      expect((result as CachedBoxFound).box.code, 'BX-CACHED');
      expect(adapter.requests, isEmpty);
    });

    test('falls back to the public ficha outside the cached window', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, publicBoxJson(code: 'BX-FAR')),
      );

      final result = await resolverOn(adapter).resolve(const BoxCode('BX-FAR'));

      expect((result as PublicBoxFound).box.code, 'BX-FAR');
      expect(adapter.requests.single.path, '/b/BX-FAR');
    });

    test('offline and uncached, the reason survives to the screen', () async {
      final result = await resolverOn(
        OfflineHttpAdapter(),
      ).resolve(const BoxCode('BX-FAR'));

      expect((result as ScanResolutionFailed).failure, isA<NetworkFailure>());
    });

    test(
      'a code the server does not know is a failure, not an empty screen',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(404, {
            'error': {'code': 'NOT_FOUND', 'message': 'no existe'},
          }),
        );

        final result = await resolverOn(
          adapter,
        ).resolve(const BoxCode('BX-NOPE'));

        expect(
          (result as ScanResolutionFailed).failure,
          isA<NotFoundFailure>(),
        );
      },
    );
  });

  group('a pallet code', () {
    test('resolves through the public ficha', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, publicPalletJson(code: 'TM-0001')),
      );

      final result = await resolverOn(
        adapter,
      ).resolve(const PalletCode('TM-0001'));

      expect((result as PublicPalletFound).pallet.centerName, 'Centro Caracas');
      expect(adapter.requests.single.path, '/p/TM-0001');
    });
  });

  group('a donation code', () {
    test('resolves through the authenticated record', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, donationJson(code: 'DN-0001')),
      );

      final result = await resolverOn(
        adapter,
      ).resolve(const DonationCode('DN-0001'));

      expect((result as DonationFound).donation.code, 'DN-0001');
      expect(adapter.requests.single.path, '/v1/donations/DN-0001');
    });
  });

  test('an unrecognized payload never reaches the network', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const {}));

    final result = await resolverOn(
      adapter,
    ).resolve(const UnrecognizedCode('https://example.com/promo'));

    expect((result as ScanNotRecognized).raw, 'https://example.com/promo');
    expect(adapter.requests, isEmpty);
  });
}
