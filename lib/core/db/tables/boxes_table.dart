import 'package:drift/drift.dart';

/// The centre's boxes, a read mirror of `GET /v1/boxes`.
///
/// [status] is stored as text without being interpreted: what each state means,
/// and which ones count towards what, is the backend's rule. The client shows
/// it and orders by it, never deduces it.
@DataClassName('BoxRow')
class Boxes extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get centerId => text()();
  TextColumn get productTypeId => text()();
  IntColumn get quantity => integer()();
  TextColumn get unit => text()();
  TextColumn get status => text()();
  TextColumn get batch => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// A decimal from the server, stored as text for the same reason as the
  /// catalogue's unit weight.
  TextColumn get weightKg => text().nullable()();
  DateTimeColumn get sealedAt => dateTime().nullable()();
  TextColumn get palletId => text().nullable()();
  TextColumn get intakeId => text().nullable()();
  TextColumn get rejectReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
