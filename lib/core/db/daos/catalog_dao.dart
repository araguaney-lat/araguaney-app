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

  /// El producto cuyo código de barras es [gtin], si está descargado.
  ///
  /// Es la consulta que hace que escanear funcione sin señal: el catálogo local
  /// guarda el `gtin` que sirvió el servidor, con su visibilidad por campaña.
  Future<ProductTypeRow?> findByGtin(String gtin) => (select(
    productTypes,
  )..where((t) => t.gtin.equals(gtin))).getSingleOrNull();

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

  /// Guarda un producto suelto, el que se acaba de crear o corregir.
  ///
  /// It is not a merge of the catalogue — [replaceAll] stays the only way the
  /// window is rebuilt. It is one row the server just confirmed, put where
  /// capture can find it: a product is created while somebody is holding it,
  /// and waiting for the next sync would mean creating it and still not being
  /// able to use it.
  ///
  /// `insertOrReplace` and not `insertOnConflictUpdate`: the second leaves out
  /// the columns that arrived null, so a product that **stopped** belonging to
  /// a campaign would keep the old one locally. Promotion is exactly that —
  /// the server clears `campaign_id` — and the row has to say so.
  Future<void> upsert(ProductTypeRow row) =>
      into(productTypes).insert(row, mode: InsertMode.insertOrReplace);
}
