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

/// Base local del modelo de lectura.
///
/// Guarda lo que el servidor sirvió para que consultar funcione sin señal. No
/// guarda nada que el servidor no haya dicho, y no deriva nada de lo guardado:
/// es una copia, no una segunda fuente de verdad.
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
  int get schemaVersion => 2;

  /// Las fechas se guardan como texto ISO-8601 con desfase horario.
  ///
  /// El formato por defecto de Drift son segundos unix interpretados en la zona
  /// local: un `DateTime` en UTC vuelve de la base convertido, y las marcas de
  /// sincronización se comparan contra lo que devuelve el servidor, que siempre
  /// viene en UTC. Guardar el desfase evita esa traducción silenciosa.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v2 agrega la cola de captura sin conexión y los códigos reservados.
      // Se crean vacías: un dispositivo que actualiza no tenía capturas
      // encoladas porque no existía dónde encolarlas.
      if (from < 2) {
        await m.createTable(queuedCaptures);
        await m.createTable(boxCodeReservations);
      }
    },
  );

  /// Vacía el modelo de **lectura**.
  ///
  /// Se usa al iniciar sesión alguien distinto en un dispositivo compartido:
  /// nadie hereda el cache del turno anterior. Va en una transacción porque un
  /// borrado a medias dejaría cajas apuntando a un catálogo que ya no está.
  ///
  /// **No toca la cola de capturas ni los códigos reservados**, y esa omisión
  /// es la funcionalidad. Lo que una persona capturó en un sótano es suyo y
  /// sigue pendiente aunque otra abra sesión en el mismo teléfono; borrarlo
  /// aquí sería perder inventario por el camino de cambiar de turno. Que no se
  /// envíe con la sesión equivocada lo garantiza el `user_id` de cada fila, no
  /// el borrado.
  Future<void> clearReadModel() => transaction(() async {
    await delete(boxes).go();
    await delete(productTypes).go();
    await delete(syncMarkers).go();
  });
}
