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

  /// Toma [count] códigos y los marca gastados **en una sola sentencia**.
  ///
  /// Reclamar y marcar tienen que ser un solo acto: leer los libres y después
  /// escribirlos deja una carrera justo en medio, y el premio de esa carrera
  /// son dos cajas con la misma etiqueta —dos bultos que el manifiesto declara
  /// como uno—. `UPDATE ... RETURNING` no tiene ese hueco: lo que devuelve es
  /// exactamente lo que marcó.
  ///
  /// Devuelve menos de [count] si el bloque se agotó. Quedarse sin códigos no
  /// puede impedir capturar, solo etiquetar.
  Future<List<String>> take(
    int count, {
    required String userId,
    required DateTime at,
  }) async {
    if (count < 1) return const [];

    final rows = await customSelect(
      'UPDATE box_code_reservations SET spent_at = ? '
      'WHERE code IN ('
      '  SELECT code FROM box_code_reservations '
      '  WHERE user_id = ? AND spent_at IS NULL '
      '  ORDER BY reserved_at LIMIT ?'
      ') RETURNING code',
      variables: [
        Variable<DateTime>(at),
        Variable<String>(userId),
        Variable<int>(count),
      ],
      readsFrom: {boxCodeReservations},
    ).get();

    return rows.map((row) => row.read<String>('code')).toList(growable: false);
  }
}
