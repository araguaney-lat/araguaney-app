import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/intakes_api.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../domain/intake_draft.dart';

/// Cómo terminó un envío de captura.
sealed class IntakeSubmission {
  const IntakeSubmission();
}

final class IntakeAccepted extends IntakeSubmission {
  const IntakeAccepted(this.intake);

  final IntakeOut intake;
}

/// El servidor pide identificar a quien dona antes de aceptar esta captura.
///
/// Es un caso propio y no un fallo cualquiera porque la interfaz responde
/// distinto: no es un error que corregir en un campo, es una pregunta que hay
/// que hacerle a la persona que está en el mostrador. **El cliente no sabe
/// desde cuándo aplica**: el umbral vive en el backend y aquí solo se reacciona
/// a su respuesta.
final class IntakeNeedsDonor extends IntakeSubmission {
  const IntakeNeedsDonor(this.failure);

  final BusinessRuleFailure failure;
}

final class IntakeRejected extends IntakeSubmission {
  const IntakeRejected(this.failure);

  final ApiFailure failure;
}

class IntakeRepository {
  IntakeRepository(this._api);

  /// El código con el que el backend pide identificar por volumen.
  static const donorRequiredCode = 'DONOR_REQUIRED_FOR_VOLUME';

  final IntakesApi _api;

  /// Envía la captura.
  ///
  /// El mismo `capture_id` puede enviarse tantas veces como haga falta: el
  /// servidor devuelve la captura que ya registró en vez de duplicarla.
  Future<IntakeSubmission> submit(IntakeDraft draft) async {
    try {
      final intake = await _api.createIntakeV1IntakesPost(
        body: draft.toRequest(),
      );
      return IntakeAccepted(intake);
    } on Object catch (error) {
      final failure = ApiErrorMapper.fromAny(error);
      if (failure is BusinessRuleFailure && failure.code == donorRequiredCode) {
        return IntakeNeedsDonor(failure);
      }
      return IntakeRejected(failure);
    }
  }

  Future<List<IntakeOut>> list({int limit = 50, int offset = 0}) =>
      _api.listIntakesV1IntakesGet(limit: limit, offset: offset);
}
