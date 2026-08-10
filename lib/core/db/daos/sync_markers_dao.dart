import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_markers_table.dart';

part 'sync_markers_dao.g.dart';

/// Recursos que la aplicación sincroniza. Son claves de una tabla, no una
/// enumeración del dominio: nombran peticiones, no conceptos del backend.
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

  /// Marca una sincronización exitosa y borra el último fallo: el dato ya no
  /// está en duda.
  ///
  /// El borrado se escribe con `Value(null)` explícito. Un `null` en la clase de
  /// datos sería indistinguible de «no toques esta columna», y el fallo
  /// anterior sobreviviría a la sincronización que lo resolvió.
  Future<void> markSynced(String resource, DateTime at) =>
      into(syncMarkers).insertOnConflictUpdate(
        SyncMarkersCompanion.insert(
          resource: resource,
          lastSyncedAt: Value(at),
          lastFailureCode: const Value(null),
        ),
      );

  /// Registra un fallo **sin tocar** la última sincronización correcta: la
  /// interfaz necesita seguir sabiendo de cuándo son los datos que muestra.
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
