import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/box_code_reservations_table.dart';

part 'box_codes_dao.g.dart';

@DriftAccessor(tables: [BoxCodeReservations])
class BoxCodesDao extends DatabaseAccessor<AppDatabase>
    with _$BoxCodesDaoMixin {
  BoxCodesDao(super.db);

  /// Guarda un bloque recién reservado.
  Future<void> store(
    Iterable<String> codes, {
    required String userId,
    required DateTime at,
  }) => batch(
    (b) => b.insertAll(boxCodeReservations, [
      for (final code in codes)
        BoxCodeReservationRow(code: code, userId: userId, reservedAt: at),
    ], mode: InsertMode.insertOrIgnore),
  );

  /// Cuántos códigos sin gastar le quedan a esta persona en el dispositivo.
  Stream<int> watchAvailable(String userId) {
    final total = boxCodeReservations.code.count();
    final query = selectOnly(boxCodeReservations)
      ..addColumns([total])
      ..where(
        boxCodeReservations.userId.equals(userId) &
            boxCodeReservations.spentAt.isNull(),
      );

    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  Future<int> available(String userId) => watchAvailable(userId).first;

  /// Toma [count] códigos y los marca gastados, en una transacción.
  ///
  /// La transacción es lo que impide que dos cajas de la misma captura reciban
  /// el mismo número: leer y marcar por separado tiene una carrera justo aquí.
  /// Devuelve menos de [count] si el bloque se agotó; quedarse sin códigos no
  /// puede impedir capturar, solo etiquetar.
  Future<List<String>> take(
    int count, {
    required String userId,
    required DateTime at,
  }) => transaction(() async {
    final rows =
        await (select(boxCodeReservations)
              ..where((t) => t.userId.equals(userId) & t.spentAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.reservedAt)])
              ..limit(count))
            .get();

    for (final row in rows) {
      await (update(boxCodeReservations)..where((t) => t.code.equals(row.code)))
          .write(BoxCodeReservationsCompanion(spentAt: Value(at)));
    }

    return rows.map((row) => row.code).toList(growable: false);
  });
}
