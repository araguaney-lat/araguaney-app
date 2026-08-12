import 'package:drift/drift.dart';

/// Códigos de caja apartados con señal para gastarse sin ella.
///
/// Un código reservado **no es inventario**: es un número apartado, y un bloque
/// que nadie usó no ensucia nada. Lo que sí importa es que se gaste una sola
/// vez, porque dos cajas con la misma etiqueta son dos bultos que el manifiesto
/// declara como uno.
///
/// [spentAt] marca el consumo **local**, al asignarlo a una caja capturada sin
/// señal. El consumo real lo registra el servidor cuando la captura llega; el
/// local existe para que dos cajas del mismo dispositivo no reciban el mismo
/// número mientras tanto.
@DataClassName('BoxCodeReservationRow')
class BoxCodeReservations extends Table {
  TextColumn get code => text()();

  /// Quién lo reservó. La cola es por persona y los códigos también: en un
  /// dispositivo compartido, dos turnos no pueden repartirse el mismo bloque.
  TextColumn get userId => text()();
  DateTimeColumn get reservedAt => dateTime()();
  DateTimeColumn get spentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {code};
}
