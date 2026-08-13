import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/clients/pallets_api.dart';
import 'package:araguaney_app/features/pallets/data/pallets_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  PalletsRepository repositoryOn(FakeHttpAdapter adapter) =>
      PalletsRepository(PalletsApi(fakeDio(adapter)));

  test('adding a box sends the code under the key the backend reads', () async {
    // El contrato declara ese cuerpo sin tipar, así que la llave se escribió a
    // mano y esta prueba es lo que impide que se desincronice en silencio.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, palletDetailJson()),
    );

    final outcome = await repositoryOn(
      adapter,
    ).addBox(palletId: 'pallet-1', boxCode: 'BX-0007');

    expect(outcome, isA<PalletChanged<dynamic>>());
    expect(adapter.requests.single.path, '/v1/pallets/pallet-1/add-box');
    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body, {'code': 'BX-0007'});
  });

  test('a box the server will not take keeps its reason', () async {
    // Que la caja no esté sellada o ya esté en otra tarima es una regla suya.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(409, {
        'error': {
          'code': 'BOX_ALREADY_PALLETIZED',
          'message': 'La caja ya está en otra tarima',
        },
      }),
    );

    final outcome = await repositoryOn(
      adapter,
    ).addBox(palletId: 'pallet-1', boxCode: 'BX-0007');

    final failure = (outcome as PalletRejected).failure;
    expect(failure, isA<BusinessRuleFailure>());
    expect(failure.operatorMessage, 'La caja ya está en otra tarima');
  });

  test('closing sends the weight and the height it was given', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, palletJson()));

    await repositoryOn(
      adapter,
    ).close(palletId: 'pallet-1', grossWeightKg: '184.5', heightCm: 120);

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['gross_weight_kg'], '184.5');
    expect(body['height_cm'], 120);
  });

  test('closing without weighing is allowed', () async {
    // Una báscula rota no puede impedir cerrar una tarima ya armada.
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, palletJson()));

    final outcome = await repositoryOn(adapter).close(palletId: 'pallet-1');

    expect(outcome, isA<PalletChanged<dynamic>>());
    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['gross_weight_kg'], isNull);
    expect(body['height_cm'], isNull);
  });

  test('removing a box asks by its code', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, palletDetailJson()),
    );

    await repositoryOn(
      adapter,
    ).removeBox(palletId: 'pallet-1', boxCode: 'BX-0007');

    expect(adapter.requests.single.path, '/v1/pallets/pallet-1/boxes/BX-0007');
    expect(adapter.requests.single.method, 'DELETE');
  });

  test('no signal is a rejection that keeps its retryable nature', () async {
    final outcome = await repositoryOn(
      OfflineHttpAdapter(),
    ).addBox(palletId: 'pallet-1', boxCode: 'BX-0007');

    final failure = (outcome as PalletRejected).failure;
    expect(failure, isA<NetworkFailure>());
    expect(failure.isRetryable, isTrue);
  });
}
