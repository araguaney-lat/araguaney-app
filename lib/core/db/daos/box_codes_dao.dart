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
    String? centerId,
    required DateTime at,
  }) => batch(
    (b) => b.insertAll(boxCodeReservations, [
      for (final code in codes)
        BoxCodeReservationRow(
          code: code,
          userId: userId,
          centerId: centerId,
          reservedAt: at,
        ),
    ], mode: InsertMode.insertOrIgnore),
  );

  /// Cuántos códigos sin gastar le quedan a esta persona en el dispositivo.
  ///
  /// [centerId] narrows the count to the ones that are good where the work is
  /// happening. Null counts every one, which is right for a session that
  /// belongs to a single centre: there are no two centres to confuse.
  Stream<int> watchAvailable(String userId, {String? centerId}) {
    final total = boxCodeReservations.code.count();
    final query = selectOnly(boxCodeReservations)
      ..addColumns([total])
      ..where(
        boxCodeReservations.userId.equals(userId) &
            boxCodeReservations.spentAt.isNull() &
            _spendableIn(centerId),
      );

    return query.watchSingle().map((row) => row.read(total) ?? 0);
  }

  Future<int> available(String userId, {String? centerId}) =>
      watchAvailable(userId, centerId: centerId).first;

  /// Which codes can be spent in [centerId].
  ///
  /// With no working centre, all of them: the session belongs to one centre.
  /// With one, its own and the ones that carry none, which are the blocks
  /// reserved before this column existed.
  Expression<bool> _spendableIn(String? centerId) => centerId == null
      ? const Constant(true)
      : boxCodeReservations.centerId.equals(centerId) |
            boxCodeReservations.centerId.isNull();

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
  ///
  /// [centerId] keeps a block reserved for one centre from being spent in
  /// another. It travels twice into the statement because the condition is
  /// «this centre, or no centre at all».
  Future<List<String>> take(
    int count, {
    required String userId,
    String? centerId,
    required DateTime at,
  }) async {
    if (count < 1) return const [];

    final rows = await customSelect(
      'UPDATE box_code_reservations SET spent_at = ? '
      'WHERE code IN ('
      '  SELECT code FROM box_code_reservations '
      '  WHERE user_id = ? AND spent_at IS NULL '
      '    AND (? IS NULL OR center_id = ? OR center_id IS NULL) '
      '  ORDER BY reserved_at LIMIT ?'
      ') RETURNING code',
      variables: [
        Variable<DateTime>(at),
        Variable<String>(userId),
        Variable<String>(centerId),
        Variable<String>(centerId),
        Variable<int>(count),
      ],
      readsFrom: {boxCodeReservations},
    ).get();

    return rows.map((row) => row.read<String>('code')).toList(growable: false);
  }
}
