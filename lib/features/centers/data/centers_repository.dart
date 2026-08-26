import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/centers_api.dart';
import '../../../core/api/generated/models/center_create.dart';
import '../../../core/api/generated/models/center_out.dart';
import '../../../core/api/generated/models/center_update.dart';

/// How a read of centres ended.
///
/// It is returned as a value and not as an exception for the usual reason, and
/// for one of its own: **the expected refusal is a 403**. Listing centres
/// requires national administration, so a coordination session is going to get
/// one every time, and that is not an error to report but an answer the screen
/// has to know how to read without noise.
sealed class CentersOutcome<T> {
  const CentersOutcome();
}

final class CentersRead<T> extends CentersOutcome<T> {
  const CentersRead(this.value);

  final T value;
}

final class CentersRefused<T> extends CentersOutcome<T> {
  const CentersRefused(this.failure);

  final ApiFailure failure;

  /// Whether the refusal is «not your place» and not a failure.
  ///
  /// Telling them apart matters: faced with a 403 the interface stays quiet —
  /// the centre is simply not named — while faced with a network failure it has
  /// something to say.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// Reading centres.
///
/// **None of this is for administering a centre from the phone.** The cases
/// that justify it are narrow and real: confirming which centre a transfer is
/// going to, finding a contact when a shipment goes missing, and seeing that a
/// freshly approved centre exists. Configuring one belongs to the panel.
class CentersRepository {
  CentersRepository(this._centers);

  final CentersApi _centers;

  Future<CentersOutcome<List<CenterOut>>> list({bool activeOnly = true}) async {
    try {
      return CentersRead(
        await _centers.listCentersV1CentersGet(activeOnly: activeOnly),
      );
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }

  Future<CentersOutcome<CenterOut>> byId(String id) async {
    try {
      return CentersRead(
        await _centers.getCenterV1CentersCenterIdGet(centerId: id),
      );
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Adding a centre.
  ///
  /// The contract only requires the name, and nothing more is asked here:
  /// inventing required fields the server does not have would be a business
  /// rule of our own, which is exactly what this client does not carry.
  Future<CentersOutcome<CenterOut>> create(CenterCreate body) async {
    try {
      return CentersRead(await _centers.createCenterV1CentersPost(body: body));
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Correcting a centre. The whole body is optional: what changed is what gets
  /// sent.
  Future<CentersOutcome<CenterOut>> update(String id, CenterUpdate body) async {
    try {
      return CentersRead(
        await _centers.updateCenterV1CentersCenterIdPatch(
          centerId: id,
          body: body,
        ),
      );
    } on Object catch (error) {
      return CentersRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
