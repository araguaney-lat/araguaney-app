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
  ///
  /// [search] busca en el nombre, la marca y el principio activo: quien captura
  /// teclea lo que ve en la caja, que tanto puede ser la marca comercial como
  /// el genérico. La búsqueda es local a propósito —el catálogo ya está en el
  /// dispositivo— y por eso funciona igual sin señal.
  Stream<List<ProductTypeRow>> watchAll({String? category, String? search}) {
    final query = select(productTypes)
      ..orderBy([(t) => OrderingTerm(expression: t.displayName)]);

    if (category != null) {
      query.where((t) => t.category.equals(category));
    }

    final term = search?.trim();
    if (term != null && term.isNotEmpty) {
      final pattern = '%$term%';
      query.where(
        (t) =>
            t.displayName.like(pattern) |
            t.brand.like(pattern) |
            t.innName.like(pattern),
      );
    }

    return query.watch();
  }

  /// Categorías presentes en el catálogo local, para navegarlo sin teclear.
  Future<List<String>> categories() async {
    final query = selectOnly(productTypes, distinct: true)
      ..addColumns([productTypes.category])
      ..orderBy([OrderingTerm(expression: productTypes.category)]);

    final rows = await query.get();
    return rows
        .map((row) => row.read(productTypes.category)!)
        .toList(growable: false);
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
