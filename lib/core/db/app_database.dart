import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/box_codes_dao.dart';
import 'daos/boxes_dao.dart';
import 'daos/capture_queue_dao.dart';
import 'daos/catalog_dao.dart';
import 'daos/sync_markers_dao.dart';
import 'tables/box_code_reservations_table.dart';
import 'tables/boxes_table.dart';
import 'tables/product_types_table.dart';
import 'tables/queued_captures_table.dart';
import 'tables/sync_markers_table.dart';

part 'app_database.g.dart';

/// The local database behind the read model.
///
/// It stores what the server served so that reading works without signal. It
/// stores nothing the server did not say, and derives nothing from what it
/// stores: it is a copy, not a second source of truth.
@DriftDatabase(
  tables: [
    ProductTypes,
    Boxes,
    SyncMarkers,
    QueuedCaptures,
    BoxCodeReservations,
  ],
  daos: [CatalogDao, BoxesDao, SyncMarkersDao, CaptureQueueDao, BoxCodesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'araguaney'));

  @override
  int get schemaVersion => 3;

  /// Dates are stored as ISO-8601 text with the offset.
  ///
  /// Drift's default is unix seconds read in the local zone: a `DateTime` in
  /// UTC comes back from the database converted, and the sync markers are
  /// compared against what the server returns, which is always UTC. Storing the
  /// offset avoids that silent translation.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 adds the offline capture queue and the reserved codes. They are
      // created empty: a device that updates had no queued captures, because
      // there was nowhere to queue them.
      if (from < 2) {
        await m.createTable(queuedCaptures);
        await m.createTable(boxCodeReservations);
      }
      // v3 records which centre a reserved block belongs to. Existing rows
      // keep a null centre and stay spendable: reserving has always required
      // belonging to a centre, so those codes can only be from one.
      if (from < 3) {
        await m.addColumn(boxCodeReservations, boxCodeReservations.centerId);
      }
    },
  );

  /// Empties the **read** model.
  ///
  /// It is used when somebody different signs in on a shared device: nobody
  /// inherits the previous shift's cache. It runs in a transaction because a
  /// half-finished delete would leave boxes pointing at a catalogue that is no
  /// longer there.
  ///
  /// **It does not touch the capture queue or the reserved codes**, and that
  /// omission is the feature. What somebody captured in a basement is theirs
  /// and stays pending even if another person signs in on the same phone;
  /// deleting it here would mean losing inventory on the way through a change
  /// of shift. What keeps it from being sent under the wrong session is the
  /// `user_id` on each row, not deletion.
  Future<void> clearReadModel() => transaction(() async {
    await delete(boxes).go();
    await delete(productTypes).go();
    await delete(syncMarkers).go();
  });
}
