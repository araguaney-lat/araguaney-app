import 'package:drift/drift.dart';

/// Catálogo de tipos de producto, tal como lo sirve el servidor.
///
/// La columna que importa entender es [campaignId]: la visibilidad por campaña
/// se guarda exactamente como vino en `GET /v1/product-types`. Aquí no se
/// decide qué es elegible; se conserva la respuesta del servidor para que un
/// producto que se puede elegir sin señal sea uno que el servidor va a aceptar.
@DataClassName('ProductTypeRow')
class ProductTypes extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get category => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get form => text().nullable()();
  TextColumn get strength => text().nullable()();
  TextColumn get defaultUnit => text().nullable()();
  TextColumn get gtin => text().nullable()();
  TextColumn get innName => text().nullable()();
  BoolColumn get isControlled => boolean()();
  IntColumn get minShelfLifeDays => integer().nullable()();

  /// Decimal del servidor. Se guarda como texto para no perder precisión al
  /// pasar por un `double`.
  TextColumn get unitWeightKg => text().nullable()();
  TextColumn get unspscCode => text().nullable()();

  /// Campaña que restringe la visibilidad del producto, o nulo si es general.
  TextColumn get campaignId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
