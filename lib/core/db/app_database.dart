import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/boxes_dao.dart';
import 'daos/catalog_dao.dart';
import 'daos/sync_markers_dao.dart';
import 'tables/boxes_table.dart';
import 'tables/product_types_table.dart';
import 'tables/sync_markers_table.dart';

part 'app_database.g.dart';

/// Base local del modelo de lectura.
///
/// Guarda lo que el servidor sirvió para que consultar funcione sin señal. No
/// guarda nada que el servidor no haya dicho, y no deriva nada de lo guardado:
/// es una copia, no una segunda fuente de verdad.
@DriftDatabase(
  tables: [ProductTypes, Boxes, SyncMarkers],
  daos: [CatalogDao, BoxesDao, SyncMarkersDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'araguaney'));

  @override
  int get schemaVersion => 1;

  /// Las fechas se guardan como texto ISO-8601 con desfase horario.
  ///
  /// El formato por defecto de Drift son segundos unix interpretados en la zona
  /// local: un `DateTime` en UTC vuelve de la base convertido, y las marcas de
  /// sincronización se comparan contra lo que devuelve el servidor, que siempre
  /// viene en UTC. Guardar el desfase evita esa traducción silenciosa.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  /// La estrategia de migración se declara desde la versión 1 aunque no tenga
  /// nada que migrar todavía: la versión que rompe dispositivos es la segunda,
  /// y para entonces el sitio donde escribirla ya tiene que existir.
  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());

  /// Vacía el modelo de lectura completo.
  ///
  /// Se usa al iniciar sesión alguien distinto en un dispositivo compartido:
  /// nadie hereda el cache del turno anterior. Va en una transacción porque un
  /// borrado a medias dejaría cajas apuntando a un catálogo que ya no está.
  Future<void> clearReadModel() => transaction(() async {
    await delete(boxes).go();
    await delete(productTypes).go();
    await delete(syncMarkers).go();
  });
}
