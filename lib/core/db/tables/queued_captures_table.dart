import 'package:drift/drift.dart';

/// Where a queued capture stands.
enum QueuedCaptureStatus {
  /// Waiting for signal. It retries on its own.
  pending,

  /// The server refused it over a business rule. **It stops retrying** and
  /// waits for a person to decide: retrying something that was already refused
  /// gives the same answer forever.
  rejected,
}

/// Captures made without signal, waiting to get out of the basement.
///
/// Three columns carry the queue's invariants:
///
/// - [captureId] is the **primary key**. The idempotency key is generated
///   before the first attempt and never changes; making it the table's key
///   makes queueing the same capture twice impossible, and SQLite guarantees
///   that rather than a check somebody can forget.
/// - [userId] makes the queue each person's own. A centre device is shared, and
///   changing shift cannot send the previous one's captures.
/// - [payload] stores the request **already built**, as JSON. What comes out of
///   the basement is exactly what was captured: neither a catalogue that
///   changed meanwhile nor a migration of the interface can rewrite it.
@DataClassName('QueuedCaptureRow')
class QueuedCaptures extends Table {
  TextColumn get captureId => text()();
  TextColumn get userId => text()();

  /// The body of `POST /v1/intakes`, serialised.
  TextColumn get payload => text()();

  /// A readable summary for the pending screen, worked out when queueing: the
  /// payload does not have to be read again to say what is inside.
  TextColumn get summary => text()();
  IntColumn get boxCount => integer()();

  TextColumn get status => textEnum<QueuedCaptureStatus>()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// The code and message of the last refusal, so the screen can show the
  /// server's own reason.
  TextColumn get lastFailureCode => text().nullable()();
  TextColumn get lastFailureMessage => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {captureId};
}
