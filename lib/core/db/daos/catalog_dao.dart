import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/product_types_table.dart';

part 'catalog_dao.g.dart';

/// Access to the cached catalogue.
@DriftAccessor(tables: [ProductTypes])
class CatalogDao extends DatabaseAccessor<AppDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.db);

  /// The visible catalogue, ordered by name. [category] filters the same way
  /// the endpoint's parameter does, so the screen does not have to filter a
  /// possibly long list in memory.
  ///
  /// [search] looks at the name, the brand and the active ingredient: whoever
  /// is capturing types what they see on the box, which can be the brand name
  /// as easily as the generic one. The search is deliberately local — the
  /// catalogue is already on the device — which is why it works the same
  /// without signal.
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

  /// The categories present in the local catalogue, for browsing it without
  /// typing.
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

  /// The product whose barcode is [gtin], if it is downloaded.
  ///
  /// This is the query that makes scanning work without signal: the local
  /// catalogue keeps the `gtin` the server served, with its campaign
  /// visibility.
  Future<ProductTypeRow?> findByGtin(String gtin) => (select(
    productTypes,
  )..where((t) => t.gtin.equals(gtin))).getSingleOrNull();

  Future<ProductTypeRow?> findById(String id) =>
      (select(productTypes)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Replaces the whole catalogue with [rows], in a single transaction.
  ///
  /// It is deliberately a replacement rather than a merge: a product type the
  /// server stopped serving has to disappear from the device. Merging would
  /// leave the application offering, without signal, something the server
  /// already refuses.
  Future<void> replaceAll(Iterable<ProductTypeRow> rows) =>
      transaction(() async {
        await delete(productTypes).go();
        await batch((b) => b.insertAll(productTypes, rows));
      });

  /// Stores a single product, the one just created or corrected.
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
