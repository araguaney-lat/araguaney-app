import 'package:araguaney_app/core/api/generated/clients/donations_api.dart';
import 'package:araguaney_app/core/api/generated/models/donation_out.dart';
import 'package:araguaney_app/features/donations/data/donations_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  DonationsRepository repositoryFor(FakeHttpAdapter adapter) =>
      DonationsRepository(DonationsApi(fakeDio(adapter)));

  group('what is coming and what arrived', () {
    test('they are two questions, and the server is told which', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [donationJson()]),
      );

      await repositoryFor(adapter).list(incoming: true);
      await repositoryFor(adapter).list(incoming: false);

      expect(adapter.requests.first.queryParameters['incoming'], true);
      expect(adapter.requests.last.queryParameters['incoming'], false);
    });
  });

  group('receiving', () {
    test('only the exceptions travel', () async {
      // The server takes anything unmarked as received. Sending a full list
      // would mean this screen decides what «complete» means, which is the
      // server's rule and not a convenience of ours.
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, donationJson()));

      await repositoryFor(adapter).receive(
        code: 'DN-0001',
        results: const {'item-2': ReceptionResult.missing},
      );

      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['results'], {'item-2': 'MISSING'});
      expect(body['extras'], isEmpty);
      expect(adapter.requests.single.path, '/v1/donations/DN-0001/receive');
    });

    test('a national session names the centre it is receiving in', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, donationJson()));

      await repositoryFor(
        adapter,
      ).receive(code: 'DN-0001', centerId: 'center-7');

      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['center_id'], 'center-7');
    });

    test('a refusal comes back as a value, with the server reason', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(400, {
          'error': {
            'code': 'ALREADY_RECEIVED',
            'message': 'Esta donación ya fue recibida',
          },
        }),
      );

      final outcome = await repositoryFor(adapter).receive(code: 'DN-0001');

      expect(outcome, isA<DonationsRefused<DonationOut>>());
      expect(
        (outcome as DonationsRefused<DonationOut>).failure.message,
        'Esta donación ya fue recibida',
      );
    });
  });

  group('reading a label', () {
    test('what comes back is unwrapped from «suggested»', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, {
          'suggested': {'batch': 'L-42', 'expiry_date': '2027-01-31'},
        }),
      );

      final outcome = await repositoryFor(
        adapter,
      ).readLabel(code: 'DN-0001', photoId: 'photo-1');

      expect((outcome as DonationsRead<Map<String, String>>).value, {
        'batch': 'L-42',
        'expiry_date': '2027-01-31',
      });
    });

    test('nothing read is an empty answer, not a broken one', () async {
      // The capability can be off, out of budget, or the provider silent. None
      // of those stop anybody from typing what they are holding.
      final adapter = FakeHttpAdapter(
        (_) => const FakeResponse(200, {'suggested': <String, Object?>{}}),
      );

      final outcome = await repositoryFor(
        adapter,
      ).readLabel(code: 'DN-0001', photoId: 'photo-1');

      expect((outcome as DonationsRead<Map<String, String>>).value, isEmpty);
    });
  });

  group('a photo', () {
    test('its link is signed by the server and asked for on opening', () async {
      final adapter = FakeHttpAdapter(
        (_) => const FakeResponse(200, {'url': 'https://files.invalid/a.jpg'}),
      );

      final outcome = await repositoryFor(
        adapter,
      ).photoUrl(code: 'DN-0001', photoId: 'photo-1');

      expect(
        (outcome as DonationsRead<String>).value,
        'https://files.invalid/a.jpg',
      );
      expect(
        adapter.requests.single.path,
        '/v1/donations/DN-0001/photos/photo-1/url',
      );
    });
  });
}
