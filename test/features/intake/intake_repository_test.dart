import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/features/intake/data/intake_repository.dart';
import 'package:araguaney_app/features/intake/domain/box_draft_input.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  final draft = const IntakeDraft(captureId: 'capture-1').addBox(
    BoxDraftInput(productType: productTypeRow(), quantity: 10, unit: 'unidad'),
  );

  IntakeRepository repositoryOn(FakeHttpAdapter adapter) =>
      IntakeRepository(IntakesApi(fakeDio(adapter)));

  test('an accepted capture returns what the server registered', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));

    final result = await repositoryOn(adapter).submit(draft);

    expect((result as IntakeAccepted).intake.id, 'intake-1');
  });

  test('the capture id travels in the body', () async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));

    await repositoryOn(adapter).submit(draft);

    expect(adapter.requests.single.data['capture_id'], 'capture-1');
  });

  test('being asked to identify the donor is its own outcome', () async {
    // No es un error de campo que corregir: es una pregunta para la persona
    // que está en el mostrador, y la interfaz responde distinto.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(422, {
        'error': {
          'code': IntakeRepository.donorRequiredCode,
          'message':
              'Esta donación supera el volumen que puede quedar anónimo.',
          'field': 'donor',
        },
      }),
    );

    final result = await repositoryOn(adapter).submit(draft);

    expect(result, isA<IntakeNeedsDonor>());
    expect(
      (result as IntakeNeedsDonor).failure.operatorMessage,
      contains('supera el volumen'),
    );
  });

  test('any other business rejection keeps the server reason', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(422, {
        'error': {
          'code': 'SHELF_LIFE_TOO_SHORT',
          'message': 'La caducidad no alcanza el mínimo de la campaña',
          'field': 'expiry_date',
        },
      }),
    );

    final result = await repositoryOn(adapter).submit(draft);

    final failure = (result as IntakeRejected).failure;
    expect(failure, isA<BusinessRuleFailure>());
    expect(
      failure.operatorMessage,
      'La caducidad no alcanza el mínimo de la campaña',
    );
    expect(failure.field, 'expiry_date');
  });

  test('no signal is a rejection the screen can retry', () async {
    final result = await repositoryOn(OfflineHttpAdapter()).submit(draft);

    final failure = (result as IntakeRejected).failure;
    expect(failure, isA<NetworkFailure>());
    expect(failure.isRetryable, isTrue);
  });
}
