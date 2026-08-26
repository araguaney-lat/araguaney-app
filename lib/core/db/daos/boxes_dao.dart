import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/boxes_table.dart';
import '../tables/product_types_table.dart';

part 'boxes_dao.g.dart';

/// A box with its product's name already resolved.
///
/// The name can be missing: the box window and the catalogue sync separately,
/// so a box can arrive before its product type. The interface shows the code in
/// that case, which is what is printed on the label.
class BoxWithProduct {
  const BoxWithProduct({required this.box, this.productName});

  final BoxRow box;
  final String? productName;
}

@DriftAccessor(tables: [Boxes, ProductTypes])
class BoxesDao extends DatabaseAccessor<AppDatabase> with _$BoxesDaoMixin {
  BoxesDao(super.db);

  /// The cached boxes, most recent first.
  ///
  /// [centerId] narrows them to one centre. The cache holds whatever the server
  /// served, and for a national administrator that is every centre's boxes —
  /// a list that cannot be checked against the shelf in front of anybody.
  Stream<List<BoxWithProduct>> watchAll({String? centerId}) {
    final query =
        select(boxes).join([
          leftOuterJoin(
            productTypes,
            productTypes.id.equalsExp(boxes.productTypeId),
          ),
        ])..orderBy([
          OrderingTerm(expression: boxes.createdAt, mode: OrderingMode.desc),
        ]);
    if (centerId != null) query.where(boxes.centerId.equals(centerId));

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => BoxWithProduct(
              box: row.readTable(boxes),
              productName: row.readTableOrNull(productTypes)?.displayName,
            ),
          )
          .toList(growable: false),
    );
  }

  /// One box with its product, for the record.
  Stream<BoxWithProduct?> watchWithProduct(String id) {
    final query = select(boxes).join([
      leftOuterJoin(
        productTypes,
        productTypes.id.equalsExp(boxes.productTypeId),
      ),
    ])..where(boxes.id.equals(id));

    return query.watchSingleOrNull().map(
      (row) => row == null
          ? null
          : BoxWithProduct(
              box: row.readTable(boxes),
              productName: row.readTableOrNull(productTypes)?.displayName,
            ),
    );
  }

  Stream<BoxRow?> watchById(String id) =>
      (select(boxes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Looks up by the code printed on the label, which is what a scan
  /// carries.
  Future<BoxRow?> findByCode(String code) =>
      (select(boxes)..where((t) => t.code.equals(code))).getSingleOrNull();

  Future<BoxRow?> findById(String id) =>
      (select(boxes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> count() async {
    final total = boxes.id.count();
    final row = await (selectOnly(boxes)..addColumns([total])).getSingle();
    return row.read(total) ?? 0;
  }

  /// Replaces the cached window with [rows].
  ///
  /// Same as the catalogue: whatever the server stopped serving inside the
  /// window disappears, so the list does not accumulate ghost boxes.
  Future<void> replaceAll(Iterable<BoxRow> rows) => transaction(() async {
    await delete(boxes).go();
    await batch((b) => b.insertAll(boxes, rows));
  });

  /// Stores a single box, the one opened from a record.
  Future<void> upsert(BoxRow row) => into(boxes).insertOnConflictUpdate(row);
}
