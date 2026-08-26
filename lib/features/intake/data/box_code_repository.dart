import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/boxes_api.dart';
import '../../../core/api/generated/models/box_code_reserve_in.dart';
import '../../../core/db/app_database.dart';
import '../../../core/sync/sync_outcome.dart';

/// Box codes set aside while there is signal, to be spent without it.
///
/// With no code there is no printable label, and in a centre in a hurry nobody
/// goes back to a sealed box to label it later: either it leaves with its label
/// or it leaves without one for good. That is why the block is asked for
/// **before** going down to the basement, which is the only moment it can be
/// asked for.
class BoxCodeRepository {
  BoxCodeRepository({
    required BoxesApi api,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _boxesApi = api,
       _db = database,
       _now = now ?? DateTime.now;

  final BoxesApi _boxesApi;
  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<int> watchAvailable(String userId, {String? centerId}) =>
      _db.boxCodesDao.watchAvailable(userId, centerId: centerId);

  /// Asks the server for a block and stores it.
  ///
  /// How many codes fit in one request is the backend's decision; that limit is
  /// not repeated here. If it asks for too many, the server answers and this
  /// layer shows its reason.
  ///
  /// [centerId] is the centre the block is asked for, and the same one it is
  /// stored under. A session that belongs to a centre leaves it null: the
  /// server takes the centre from the token and refuses to be told otherwise.
  Future<SyncOutcome> topUp({
    required int count,
    required String userId,
    String? centerId,
  }) async {
    try {
      final block = await _boxesApi.reserveBoxCodesV1BoxesCodesReservePost(
        body: BoxCodeReserveIn(count: count, centerId: centerId),
      );
      await _db.boxCodesDao.store(
        block.codes,
        userId: userId,
        centerId: centerId,
        at: _now(),
      );
      return SyncSucceeded(at: _now(), itemCount: block.codes.length);
    } on Object catch (error) {
      return SyncFailed(ApiErrorMapper.fromAny(error));
    }
  }

  /// Takes codes from the local block for a capture made with no signal.
  ///
  /// It may return fewer than asked for. Running out of codes does not stop the
  /// capture — losing it would be far worse — it only stops those boxes being
  /// labelled until the capture reaches the server.
  Future<List<String>> take(
    int count, {
    required String userId,
    String? centerId,
  }) => _db.boxCodesDao.take(
    count,
    userId: userId,
    centerId: centerId,
    at: _now(),
  );
}
