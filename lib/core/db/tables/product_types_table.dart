import 'package:drift/drift.dart';

/// The catalogue of product types, exactly as the server serves it.
///
/// The column worth understanding is [campaignId]: campaign visibility is
/// stored precisely as it arrived from `GET /v1/product-types`. Nothing here
/// decides what is eligible; the server's answer is kept so that a product that
/// can be chosen without signal is one the server is going to accept.
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

  /// A decimal from the server. Stored as text so no precision is lost passing
  /// through a `double`.
  TextColumn get unitWeightKg => text().nullable()();
  TextColumn get unspscCode => text().nullable()();

  /// The campaign that restricts the product's visibility, or null if it is
  /// general.
  TextColumn get campaignId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
