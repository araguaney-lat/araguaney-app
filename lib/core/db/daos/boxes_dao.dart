import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/boxes_table.dart';
import '../tables/product_types_table.dart';

part 'boxes_dao.g.dart';

/// Una caja con el nombre del producto ya resuelto.
///
/// El nombre puede faltar: la ventana de cajas y el catálogo se sincronizan por
/// separado, así que una caja puede llegar antes que su tipo de producto. La
/// interfaz muestra el código en ese caso, que es lo que está impreso en la
/// etiqueta.
class BoxWithProduct {
  const BoxWithProduct({required this.box, this.productName});

  final BoxRow box;
  final String? productName;
}

@DriftAccessor(tables: [Boxes, ProductTypes])
class BoxesDao extends DatabaseAccessor<AppDatabase> with _$BoxesDaoMixin {
  BoxesDao(super.db);

  /// Cajas cacheadas, las más recientes primero.
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

  /// Una caja con su producto, para el detalle.
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

  /// Busca por el código impreso en la etiqueta, que es lo que trae un escaneo.
  Future<BoxRow?> findByCode(String code) =>
      (select(boxes)..where((t) => t.code.equals(code))).getSingleOrNull();

  Future<BoxRow?> findById(String id) =>
      (select(boxes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> count() async {
    final total = boxes.id.count();
    final row = await (selectOnly(boxes)..addColumns([total])).getSingle();
    return row.read(total) ?? 0;
  }

  /// Sustituye la ventana cacheada por [rows].
  ///
  /// Igual que el catálogo: lo que el servidor dejó de servir dentro de la
  /// ventana desaparece, para que la lista no acumule cajas fantasma.
  Future<void> replaceAll(Iterable<BoxRow> rows) => transaction(() async {
    await delete(boxes).go();
    await batch((b) => b.insertAll(boxes, rows));
  });

  /// Guarda una caja suelta, la que se abrió desde el detalle.
  Future<void> upsert(BoxRow row) => into(boxes).insertOnConflictUpdate(row);
}
