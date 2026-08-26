import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/center_applications_api.dart';
import '../../../core/api/generated/models/center_application_out.dart';
import '../../../core/api/generated/models/center_application_reject.dart';

/// How a read or a decision about applications ended.
sealed class ApplicationsOutcome<T> {
  const ApplicationsOutcome();
}

final class ApplicationsRead<T> extends ApplicationsOutcome<T> {
  const ApplicationsRead(this.value);

  final T value;
}

final class ApplicationsRefused<T> extends ApplicationsOutcome<T> {
  const ApplicationsRefused(this.failure);

  final ApiFailure failure;

  /// Whether the refusal is «not your place» and not a failure.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// The queue of centre applications, and the two decisions.
///
/// **The queue only brings what is waiting for review.** The backend filters by
/// `PENDING_REVIEW`, oldest to newest, and a national administration sees it
/// narrowed to its country while a superadministration sees them all. So this
/// is a queue and not a history: deciding one takes it out.
///
/// Both decisions require a connection, and not for convenience: approving
/// creates things on the server and rejecting sends an email.
class CenterApplicationsRepository {
  CenterApplicationsRepository(this._applications);

  final CenterApplicationsApi _applications;

  Future<ApplicationsOutcome<List<CenterApplicationOut>>> queue() async {
    try {
      return ApplicationsRead(
        await _applications.listQueueV1CenterApplicationsGet(),
      );
    } on Object catch (error) {
      return ApplicationsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Approving, which does **three things** on the server: it creates the
  /// centre, adds whoever applied as its coordination, and emails them a
  /// temporary password.
  ///
  /// None of that is undone from here, and that is why the screen says so
  /// beforehand.
  Future<ApplicationsOutcome<CenterApplicationOut>> approve(String id) async {
    try {
      return ApplicationsRead(
        await _applications
            .approveApplicationV1CenterApplicationsAppIdApprovePost(appId: id),
      );
    } on Object catch (error) {
      return ApplicationsRefused(ApiErrorMapper.fromAny(error));
    }
  }

  /// Rejecting. The reason **travels by email to whoever applied**, so what is
  /// written here is going to be read by somebody outside the platform.
  Future<ApplicationsOutcome<CenterApplicationOut>> reject(
    String id,
    String reason,
  ) async {
    try {
      return ApplicationsRead(
        await _applications
            .rejectApplicationV1CenterApplicationsAppIdRejectPost(
              appId: id,
              body: CenterApplicationReject(reason: reason),
            ),
      );
    } on Object catch (error) {
      return ApplicationsRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
