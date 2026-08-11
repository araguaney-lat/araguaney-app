import 'package:drift/drift.dart';

/// Cajas del centro, espejo de lectura de `GET /v1/boxes`.
///
/// [status] se guarda como texto sin interpretarlo: qué significa cada estado y
/// cuáles cuentan para qué es una regla del backend. El cliente lo muestra y lo
/// ordena, nunca lo deduce.
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

  /// Decimal del servidor, guardado como texto por la misma razón que el peso
  /// unitario del catálogo.
  TextColumn get weightKg => text().nullable()();
  DateTimeColumn get sealedAt => dateTime().nullable()();
  TextColumn get palletId => text().nullable()();
  TextColumn get intakeId => text().nullable()();
  TextColumn get rejectReason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
