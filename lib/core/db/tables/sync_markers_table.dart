import 'package:drift/drift.dart';

/// Cuándo se sincronizó por última vez cada recurso, y con qué resultado.
///
/// Existe para que la interfaz pueda decir «datos de hace 12 minutos» en vez de
/// mostrar una lista vieja sin avisar. [lastFailureCode] conserva el código del
/// último fallo para explicar por qué el dato no se pudo refrescar.
@DataClassName('SyncMarkerRow')
class SyncMarkers extends Table {
  /// Identificador del recurso: `product_types`, `boxes`.
  TextColumn get resource => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get lastFailureCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {resource};
}
