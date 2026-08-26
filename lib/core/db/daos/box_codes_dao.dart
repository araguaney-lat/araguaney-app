import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/box_code_reservations_table.dart';

part 'box_codes_dao.g.dart';

@DriftAccessor(tables: [BoxCodeReservations])
class BoxCodesDao extends DatabaseAccessor<AppDatabase>
    with _$BoxCodesDaoMixin {
  BoxCodesDao(super.db);

  /// Stores a freshly reserved block.
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

  /// How many unspent codes this person has left on the device.
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

  /// Takes [count] codes and marks them spent **in a single statement**.
  ///
  /// Claiming and marking have to be one act: reading the free ones and then
  /// writing them leaves a race right in the middle, and the prize for winning
  /// that race is two boxes with the same label — two parcels the manifest
  /// declares as one. `UPDATE ... RETURNING` has no such gap: what it returns
  /// is exactly what it marked.
  ///
  /// It returns fewer than [count] if the block ran out. Running out of codes
  /// cannot stop anybody capturing, only labelling.
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
