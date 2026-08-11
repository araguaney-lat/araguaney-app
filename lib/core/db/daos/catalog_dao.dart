import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/product_types_table.dart';

part 'catalog_dao.g.dart';

/// Acceso al catálogo cacheado.
@DriftAccessor(tables: [ProductTypes])
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.db);

  /// Catálogo visible, ordenado por nombre. [category] filtra igual que el
  /// parámetro del endpoint, para que la pantalla no tenga que filtrar en
  /// memoria una lista que puede ser larga.
  Stream<List<ProductTypeRow>> watchAll({String? category}) {
    final query = select(productTypes)
      ..orderBy([(t) => OrderingTerm(expression: t.displayName)]);
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    return query.watch();
  }

  Future<List<ProductTypeRow>> all() => select(productTypes).get();

  Future<ProductTypeRow?> findById(String id) =>
      (select(productTypes)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Sustituye el catálogo entero por [rows], en una sola transacción.
  ///
  /// Es un reemplazo y no una fusión a propósito: un tipo de producto que el
  /// servidor dejó de servir tiene que desaparecer del dispositivo. Fusionar
  /// dejaría ofreciendo sin señal algo que el servidor ya rechaza.
  Future<void> replaceAll(Iterable<ProductTypeRow> rows) =>
      transaction(() async {
        await delete(productTypes).go();
        await batch((b) => b.insertAll(productTypes, rows));
      });
}
