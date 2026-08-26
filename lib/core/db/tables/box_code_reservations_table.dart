import 'package:drift/drift.dart';

/// Box codes set aside with signal, to be spent without it.
///
/// A reserved code **is not inventory**: it is a number put aside, and a block
/// nobody used dirties nothing. What matters is that it is spent once, because
/// two boxes with the same label are two parcels the manifest declares as
/// one.
///
/// [spentAt] marks the **local** spending, when it is assigned to a box
/// captured without signal. The real spending is recorded by the server when
/// the capture arrives; the local one exists so two boxes on the same device do
/// not get the same number in the meantime.
@DataClassName('BoxCodeReservationRow')
class BoxCodeReservations extends Table {
  TextColumn get code => text()();

  /// Who reserved it. The queue is per person and so are the codes: on a
  /// shared device, two shifts cannot split the same block between them.
  TextColumn get userId => text()();

  /// Which centre the block was reserved for.
  ///
  /// The server hands out codes **for a centre**, so spending them in another
  /// one puts the wrong centre's label on a physical box. A national
  /// administrator can change working centre with a block half spent, and
  /// without this column the rest of it would be spent there.
  ///
  /// Null in rows written before this column existed, and those are spendable
  /// anywhere. That is not a convenient exception: reserving has always
  /// required belonging to a centre — the server refuses anybody who has none —
  /// so a row without one can only belong to somebody who had exactly one.
  TextColumn get centerId => text().nullable()();
  DateTimeColumn get reservedAt => dateTime()();
  DateTimeColumn get spentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}
