import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/queued_captures_table.dart';

part 'capture_queue_dao.g.dart';

/// Access to the capture queue.
///
/// **Every query carries `userId`.** It is not extra caution: on a centre
/// device shared between shifts, an unfiltered query would send somebody else's
/// captures under the session of whoever is standing there.
@DriftAccessor(tables: [QueuedCaptures])
class CaptureQueueDao extends DatabaseAccessor<AppDatabase>
    with _$CaptureQueueDaoMixin {
  CaptureQueueDao(super.db);

  Stream<List<QueuedCaptureRow>> watchAll(String userId) =>
      (select(queuedCaptures)
            ..where((t) => t.userId.equals(userId))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();

  /// How many of this person's captures are still waiting for signal.
  Stream<int> watchPendingCount(String userId) {
    final total = queuedCaptures.captureId.count();
    final query = selectOnly(queuedCaptures)
      ..addColumns([total])
      ..where(
        queuedCaptures.userId.equals(userId) &
            queuedCaptures.status.equalsValue(QueuedCaptureStatus.pending),
      );

    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  /// The ones to try, in the order they were captured.
  Future<List<QueuedCaptureRow>> pending(String userId) =>
      (select(queuedCaptures)
            ..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(QueuedCaptureStatus.pending),
            )
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Future<QueuedCaptureRow?> findById(String captureId) => (select(
    queuedCaptures,
  )..where((t) => t.captureId.equals(captureId))).getSingleOrNull();

  /// Queues one. If that key was already there it is not duplicated: the
  /// primary key prevents it and this write does not overwrite it.
  Future<void> enqueue(QueuedCaptureRow row) =>
      into(queuedCaptures).insert(row, mode: InsertMode.insertOrIgnore);

  /// Counts an attempt. SQLite does the increment against the row's own value
  /// rather than a number read beforehand: two overlapping flushes cannot lose
  /// each other's count.
  Future<void> markAttempt(String captureId, DateTime at) => customUpdate(
    'UPDATE queued_captures SET attempts = attempts + 1, '
    'last_attempt_at = ? WHERE capture_id = ?',
    variables: [Variable<DateTime>(at), Variable<String>(captureId)],
    updates: {queuedCaptures},
  );

  /// Parks a refused capture with the server's reason in plain sight.
  Future<void> markRejected(
    String captureId, {
    required String code,
    required String message,
    required DateTime at,
  }) => (update(queuedCaptures)..where((t) => t.captureId.equals(captureId)))
      .write(
        QueuedCapturesCompanion(
          status: const Value(QueuedCaptureStatus.rejected),
          lastFailureCode: Value(code),
          lastFailureMessage: Value(message),
          lastAttemptAt: Value(at),
        ),
      );

  /// Records why an attempt failed when it will be repeated anyway.
  Future<void> markRetryable(
    String captureId, {
    required String code,
    required String message,
    required DateTime at,
  }) => (update(queuedCaptures)..where((t) => t.captureId.equals(captureId)))
      .write(
        QueuedCapturesCompanion(
          lastFailureCode: Value(code),
          lastFailureMessage: Value(message),
          lastAttemptAt: Value(at),
        ),
      );

  /// Puts a parked capture back in the queue.
  ///
  /// Parking means it stops retrying **by itself**, not that the case is
  /// closed: a refusal usually describes something somebody can resolve
  /// elsewhere — a missing approval, a product that has since been created —
  /// and then retrying is the right answer. The only way out offered before was
  /// discarding, and throwing away inventory to settle paperwork is the worse
  /// of the two.
  ///
  /// The previous reason is cleared because it no longer describes the row;
  /// [attempts] is left alone, because those attempts happened. And the
  /// idempotency key is still the same, so retrying cannot duplicate.
  Future<void> requeue(String captureId) =>
      (update(
        queuedCaptures,
      )..where((t) => t.captureId.equals(captureId))).write(
        const QueuedCapturesCompanion(
          status: Value(QueuedCaptureStatus.pending),
          lastFailureCode: Value(null),
          lastFailureMessage: Value(null),
        ),
      );

  /// Takes a capture out of the queue. Two places call it: a successful send,
  /// and a person discarding it on purpose. Nothing else deletes from here.
  Future<void> remove(String captureId) => (delete(
    queuedCaptures,
  )..where((t) => t.captureId.equals(captureId))).go();
}
