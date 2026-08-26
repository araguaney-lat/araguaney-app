import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/clients/shipments_api.dart';
import 'package:araguaney_app/features/incidents/data/incidents_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/l10n.dart';

void main() {
  IncidentsRepository repositoryOn(FakeHttpAdapter adapter) =>
      IncidentsRepository(ShipmentsApi(fakeDio(adapter)));

  group('reading the reception', () {
    test(
      'a shipment not reconciled yet answers with nothing, not an error',
      () async {
        // A 404 here is the answer to «has it arrived yet?», and the answer is
        // not yet. Showing it as a failure would be lying about what happened.
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(404, {
            'error': {'code': 'NOT_FOUND', 'message': 'no existe'},
          }),
        );

        expect(await repositoryOn(adapter).reception('shipment-1'), isNull);
      },
    );

    test('a reconciled shipment brings its shrinkage', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, receptionJson(received: 8, totalBoxes: 10)),
      );

      final reception = await repositoryOn(adapter).reception('shipment-1');

      expect(reception?.shrinkage.received, 8);
      expect(reception?.shrinkage.notReceived, 2);
    });

    test('a real failure still surfaces', () async {
      // With no signal it cannot be said that it has not arrived yet: it is not
      // known.
      expect(
        () => repositoryOn(OfflineHttpAdapter()).reception('shipment-1'),
        throwsA(anything),
      );
    });
  });

  group('raising an incident', () {
    test('sends the type and the description to that shipment', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, incidentJson()));

      final outcome = await repositoryOn(adapter).create(
        shipmentId: 'shipment-1',
        type: IncidentType.damage,
        description: 'Tarima mojada por lluvia en el andén',
      );

      expect(outcome, isA<IncidentCreated>());
      expect(
        adapter.requests.single.path,
        '/v1/shipments/shipment-1/incidents',
      );
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['type'], 'DAMAGE');
      expect(body['description'], 'Tarima mojada por lluvia en el andén');
    });

    test('a rejection keeps the server reason', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(403, {
          'error': {'code': 'FORBIDDEN', 'message': 'Coordinación requerida'},
        }),
      );

      final outcome = await repositoryOn(adapter).create(
        shipmentId: 'shipment-1',
        type: IncidentType.other,
        description: 'algo',
      );

      expect((outcome as IncidentRejected).failure, isA<ForbiddenFailure>());
    });
  });

  test('every incident type has a Spanish name', () async {
    final l10n = await spanish();
    for (final type in IncidentType.all) {
      expect(incidentTypeLabel(l10n, type), isNot(type));
    }
    // And a type this version does not know is shown as it is instead of
    // disappearing from the screen.
    expect(incidentTypeLabel(l10n, 'SOMETHING_NEW'), 'SOMETHING_NEW');
  });
}
