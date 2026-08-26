import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables/queued_captures_table.dart';
import '../domain/intake_draft.dart';

/// The queue of captures made without signal.
///
/// Four invariants hold it up, and all of them live in the schema or here:
///
/// 1. The idempotency key is generated before the first attempt and never
///    changes.
/// 2. The local catalogue keeps the server's per-campaign visibility, so what
///    can be chosen without signal is what the server will accept.
/// 3. The queue is per person: every row carries its `user_id` and no query of
///    this class is made without one.
/// 4. Nothing is discarded on its own. Only two paths delete a row: an accepted
///    submission and an explicit discard by a person.
class CaptureQueueRepository {
  CaptureQueueRepository({
    required AppDatabase database,
    DateTime Function()? now,
  }) : _db = database,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<List<QueuedCaptureRow>> watchAll(String userId) =>
      _db.captureQueueDao.watchAll(userId);

  Stream<int> watchPendingCount(String userId) =>
      _db.captureQueueDao.watchPendingCount(userId);

  /// Stores the capture exactly as it would be sent.
  ///
  /// The payload is serialised here and not rebuilt when it is sent: what
  /// leaves the basement is exactly what was captured, even if the catalogue
  /// changed in the meantime.
  Future<void> enqueue({required IntakeDraft draft, required String userId}) =>
      _db.captureQueueDao.enqueue(
        QueuedCaptureRow(
          captureId: draft.captureId,
          userId: userId,
          payload: jsonEncode(draft.toRequest().toJson()),
          summary: describeDraft(draft),
          boxCount: draft.boxes.length,
          status: QueuedCaptureStatus.pending,
          attempts: 0,
          createdAt: _now(),
        ),
      );

  /// The other decision a person can take in the face of a refusal: try again,
  /// usually because the reason was resolved outside the application.
  /// Invariant 4 asks for an explicit decision; it does not say the only one
  /// available has to be throwing the capture away.
  Future<void> retry(String captureId) =>
      _db.captureQueueDao.requeue(captureId);

  /// An explicit discard. It is the only deletion that does not come from an
  /// accepted submission, and that is why a person asks for it while looking at
  /// the reason for the refusal.
  Future<void> discard(String captureId) =>
      _db.captureQueueDao.remove(captureId);
}

/// How a queued capture is named on the pending screen.
///
/// **It carries no count and no sentence.** A queued capture is read days
/// later, possibly with the application in another language, and a rendered
/// «3 cajas» written into the row would freeze today's language in there. The
/// number is already a column of its own; the screen puts the two together.
String describeDraft(IntakeDraft draft) => [
  if (draft.boxes.isNotEmpty) draft.boxes.first.productType.displayName,
  ?_donorLabel(draft),
].join(' · ');

String? _donorLabel(IntakeDraft draft) {
  if (draft.donor case final donor?) {
    return donor.legalName ?? '${donor.firstName} ${donor.lastName}';
  }
  return draft.donanteLibre;
}
