import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_markers_table.dart';

part 'sync_markers_dao.g.dart';

/// The resources the application syncs. They are keys in a table rather than a
/// domain enum: they name requests, not the backend's concepts.
abstract final class SyncResource {
  static const productTypes = 'product_types';
  static const boxes = 'boxes';
}

@DriftAccessor(tables: [SyncMarkers])
class SyncMarkersDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMarkersDaoMixin {
  SyncMarkersDao(super.db);

  Stream<SyncMarkerRow?> watch(String resource) => (select(
    syncMarkers,
  )..where((t) => t.resource.equals(resource))).watchSingleOrNull();

  Future<SyncMarkerRow?> read(String resource) => (select(
    syncMarkers,
  )..where((t) => t.resource.equals(resource))).getSingleOrNull();

  /// Marks a successful sync and clears the last failure: the data is no
  /// longer in doubt.
  ///
  /// The clearing is written with an explicit `Value(null)`. A `null` in the
  /// data class would be indistinguishable from «do not touch this column», and
  /// the previous failure would outlive the sync that resolved it.
  Future<void> markSynced(String resource, DateTime at) =>
      into(syncMarkers).insertOnConflictUpdate(
        SyncMarkersCompanion.insert(
          resource: resource,
          lastSyncedAt: Value(at),
          lastFailureCode: const Value(null),
        ),
      );

  /// Records a failure **without touching** the last successful sync: the
  /// interface still needs to know how old the data it is showing is.
  Future<void> markFailed(String resource, String failureCode) async {
    final current = await read(resource);
    await into(syncMarkers).insertOnConflictUpdate(
      SyncMarkersCompanion.insert(
        resource: resource,
        lastSyncedAt: Value(current?.lastSyncedAt),
        lastFailureCode: Value(failureCode),
      ),
    );
  }
}
