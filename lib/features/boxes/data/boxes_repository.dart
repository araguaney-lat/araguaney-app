import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/boxes_api.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/boxes_dao.dart';
import '../../../core/db/daos/sync_markers_dao.dart';
import '../../../core/sync/sync_outcome.dart';
import 'box_mapper.dart';

/// The centre's boxes, from the cache first.
class BoxesRepository {
  BoxesRepository({
    required BoxesApi api,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _boxesApi = api,
       _db = database,
       _now = now ?? DateTime.now;

  /// How many boxes each request asks for.
  static const pageSize = 200;

  /// The ceiling of the cached window.
  ///
  /// The alternative — mirroring the whole centre — turns the first sync of a
  /// centre with years of history into a wait of unknown length, exactly when
  /// somebody has just installed the application. A box outside the window is
  /// opened on demand, with signal.
  ///
  /// The window **does not filter by state**: which ones matter is a backend
  /// decision, and writing a list of states here would duplicate it. It is the
  /// first [windowLimit] rows the server returns for this session, in its
  /// order.
  static const windowLimit = 500;

  final BoxesApi _boxesApi;
  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<List<BoxWithProduct>> watchBoxes({String? centerId}) =>
      _db.boxesDao.watchAll(centerId: centerId);

  Stream<BoxWithProduct?> watchBox(String id) =>
      _db.boxesDao.watchWithProduct(id);

  Future<BoxRow?> findBox(String id) => _db.boxesDao.findById(id);

  Stream<SyncMarkerRow?> watchSyncMarker() =>
      _db.syncMarkersDao.watch(SyncResource.boxes);

  /// Refreshes the cached window of boxes.
  Future<SyncOutcome> refresh() async {
    try {
      final rows = await _fetchWindow();
      await _db.boxesDao.replaceAll(rows);

      final at = _now();
      await _db.syncMarkersDao.markSynced(SyncResource.boxes, at);
      return SyncSucceeded(at: at, itemCount: rows.length);
    } on Object catch (error) {
      return _recordFailure(error);
    }
  }

  /// Fetches a single box, the one opened outside the window.
  Future<SyncOutcome> refreshBox(String id) async {
    try {
      final box = await _boxesApi.getBoxV1BoxesBoxIdGet(boxId: id);
      await _db.boxesDao.upsert(toBoxRow(box));
      return SyncSucceeded(at: _now(), itemCount: 1);
    } on Object catch (error) {
      return _recordFailure(error);
    }
  }

  /// Seals a box.
  ///
  /// It requires a connection and is not queued: sealing decides about shared
  /// state that may be changing on another device, and resolving it blind would
  /// produce two truths about the same box. The state the server returns goes
  /// into the cache, so the list reflects it straight away.
  Future<SyncOutcome> seal(String boxId) async {
    try {
      final box = await _boxesApi.sealBoxV1BoxesBoxIdSealPost(boxId: boxId);
      await _db.boxesDao.upsert(toBoxRow(box));
      return SyncSucceeded(at: _now(), itemCount: 1);
    } on Object catch (error) {
      return _recordFailure(error);
    }
  }

  Future<List<BoxRow>> _fetchWindow() async {
    final collected = <BoxRow>[];
    var offset = 0;

    while (collected.length < windowLimit) {
      final page = await _boxesApi.listBoxesV1BoxesGet(
        limit: pageSize,
        offset: offset,
      );
      collected.addAll(page.map(toBoxRow));

      // A short page means there is nothing left behind it: asking for the
      // next one would be a guaranteed empty request.
      if (page.length < pageSize) break;
      offset += pageSize;
    }

    return collected.length > windowLimit
        ? collected.sublist(0, windowLimit)
        : collected;
  }

  Future<SyncFailed> _recordFailure(Object error) async {
    final failure = ApiErrorMapper.fromAny(error);
    await _db.syncMarkersDao.markFailed(SyncResource.boxes, failure.code);
    return SyncFailed(failure);
  }
}
