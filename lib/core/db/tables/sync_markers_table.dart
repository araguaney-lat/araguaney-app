import 'package:drift/drift.dart';

/// When each resource was last synced, and how it went.
///
/// It exists so the interface can say «data from 12 minutes ago» instead of
/// showing a stale list without warning. [lastFailureCode] keeps the last
/// failure's code, to explain why the data could not be refreshed.
@DataClassName('SyncMarkerRow')
class SyncMarkers extends Table {
  /// The resource's identifier: `product_types`, `boxes`.
  TextColumn get resource => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get lastFailureCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {resource};
}
