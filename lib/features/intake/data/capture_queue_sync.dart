import 'dart:convert';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/intakes_api.dart';
import '../../../core/api/generated/models/intake_create.dart';
import '../../../core/db/app_database.dart';

/// How a flush of the queue ended.
class QueueFlushReport {
  const QueueFlushReport({
    required this.sent,
    required this.parked,
    required this.remaining,
    this.stoppedBy,
  });

  /// Captures the server accepted, which left the queue.
  final int sent;

  /// Captures parked waiting for a person's decision.
  final int parked;

  /// The ones still waiting to be retried.
  final int remaining;

  /// Why the flush was cut short, when it was.
  final ApiFailure? stoppedBy;

  bool get didAnything => sent > 0 || parked > 0;
}

/// Sends what the queue has stored.
///
/// It walks **one** person's captures in the order they were made and stops at
/// the first failure that does not depend on the capture: with no signal,
/// carrying on with the next ones only spends battery to get the same error.
class CaptureQueueSync {
  CaptureQueueSync({
    required IntakesApi api,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _intakes = api,
       _db = database,
       _now = now ?? DateTime.now;

  final IntakesApi _intakes;
  final AppDatabase _db;
  final DateTime Function() _now;

  Future<QueueFlushReport> flush(String userId) async {
    final pending = await _db.captureQueueDao.pending(userId);
    var sent = 0;
    var parked = 0;
    ApiFailure? stoppedBy;

    for (final row in pending) {
      await _db.captureQueueDao.markAttempt(row.captureId, _now());

      try {
        // The body is rebuilt from the stored JSON and not from the form:
        // retrying has to send the same thing that was captured.
        await _intakes.createIntakeV1IntakesPost(
          body: IntakeCreate.fromJson(
            jsonDecode(row.payload) as Map<String, Object?>,
          ),
        );
        // The server is idempotent by `capture_id`: if this capture was
        // already registered it returns the one it registered instead of
        // duplicating it, and the result is the same as if it had just
        // arrived.
        await _db.captureQueueDao.remove(row.captureId);
        sent++;
      } on Object catch (error) {
        final failure = ApiErrorMapper.fromAny(error);

        if (_belongsToTheCapture(failure)) {
          // The server has already decided about this capture. Sending it
          // again would give the same answer forever, so it stops being
          // retried and waits for a person to look at it, with the reason in
          // sight.
          await _db.captureQueueDao.markRejected(
            row.captureId,
            code: failure.code,
            // **The server's words, not a translation.** What is stored here
            // is read by somebody days later, perhaps with the application in
            // another language: writing down today's rendering would freeze a
            // language into the database. The code travels alongside it and
            // the screen resolves our own copy from it when it knows it.
            message: failure.message,
            at: _now(),
          );
          parked++;
          continue;
        }

        // Nothing to do with the capture: no network, an expired session or a
        // server that is down. It stays pending and the flush stops here.
        await _db.captureQueueDao.markRetryable(
          row.captureId,
          code: failure.code,
          message: failure.message,
          at: _now(),
        );
        stoppedBy = failure;
        break;
      }
    }

    final remaining = (await _db.captureQueueDao.pending(userId)).length;
    return QueueFlushReport(
      sent: sent,
      parked: parked,
      remaining: remaining,
      stoppedBy: stoppedBy,
    );
  }

  /// Whether the refusal is about **this** capture or about the road to the
  /// server.
  ///
  /// The distinction decides whether it is parked or retried, and that is why
  /// it is written as a question and not as a list of codes. A 401 says nothing
  /// bad about the capture: it says the session expired, and parking it for
  /// that would lose inventory over a credentials problem.
  static bool _belongsToTheCapture(ApiFailure failure) => switch (failure) {
    BusinessRuleFailure() => true,
    ForbiddenFailure() => true,
    NotFoundFailure() => true,
    _ => false,
  };
}
