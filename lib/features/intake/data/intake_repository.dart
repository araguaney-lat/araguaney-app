import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/intakes_api.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../domain/intake_draft.dart';

/// How submitting a capture ended.
sealed class IntakeSubmission {
  const IntakeSubmission();
}

final class IntakeAccepted extends IntakeSubmission {
  const IntakeAccepted(this.intake);

  final IntakeOut intake;
}

/// The server asks for the donor to be identified before accepting this
/// capture.
///
/// It is a case of its own and not just any failure because the interface
/// answers differently: it is not an error to correct in a field, it is a
/// question to ask the person standing at the counter. **The client does not
/// know from what point it applies**: the threshold lives in the backend and
/// all that happens here is reacting to its answer.
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

  /// The code the backend uses to ask for identification by volume.
  static const donorRequiredCode = 'DONOR_REQUIRED_FOR_VOLUME';

  final IntakesApi _api;

  /// Sends the capture.
  ///
  /// The same `capture_id` can be sent as many times as needed: the server
  /// returns the capture it already registered instead of duplicating it.
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
