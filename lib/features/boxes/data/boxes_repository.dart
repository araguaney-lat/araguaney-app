import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/boxes_api.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/boxes_dao.dart';
import '../../../core/db/daos/sync_markers_dao.dart';
import '../../../core/sync/sync_outcome.dart';
import 'box_mapper.dart';

/// Cajas del centro, primero desde el cache.
class BoxesRepository {
  BoxesRepository({
    required BoxesApi api,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _boxesApi = api,
       _db = database,
       _now = now ?? DateTime.now;

  /// Cuántas cajas pide cada petición.
  static const pageSize = 200;

  /// Tope de la ventana cacheada.
  ///
  /// La alternativa —espejar el centro entero— convierte la primera
  /// sincronización de un centro con años de historia en una espera de duración
  /// desconocida, justo cuando alguien acaba de instalar la aplicación. Una
  /// caja fuera de la ventana se abre bajo demanda con señal.
  ///
  /// La ventana **no filtra por estado**: cuáles importan es una decisión del
  /// backend, y escribir aquí una lista de estados sería duplicarla. Son las
  /// primeras [windowLimit] filas que el servidor devuelve para esta sesión, en
  /// su orden.
  static const windowLimit = 500;

  final BoxesApi _boxesApi;
  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<List<BoxWithProduct>> watchBoxes() => _db.boxesDao.watchAll();

  Stream<BoxWithProduct?> watchBox(String id) =>
      _db.boxesDao.watchWithProduct(id);

  Future<BoxRow?> findBox(String id) => _db.boxesDao.findById(id);

  Stream<SyncMarkerRow?> watchSyncMarker() =>
      _db.syncMarkersDao.watch(SyncResource.boxes);

  /// Refresca la ventana cacheada de cajas.
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

  /// Trae una caja suelta, la que se abrió fuera de la ventana.
  Future<SyncOutcome> refreshBox(String id) async {
    try {
      final box = await _boxesApi.getBoxV1BoxesBoxIdGet(boxId: id);
      await _db.boxesDao.upsert(toBoxRow(box));
      return SyncSucceeded(at: _now(), itemCount: 1);
    } on Object catch (error) {
      return _recordFailure(error);
    }
  }

  /// Sella una caja.
  ///
  /// Exige conexión y no se encola: sellar decide sobre estado compartido que
  /// puede estar cambiando en otro dispositivo, y resolverlo a ciegas
  /// produciría dos verdades sobre la misma caja. El estado que devuelve el
  /// servidor entra al cache, para que la lista lo refleje de inmediato.
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

      // Una página corta significa que no queda nada detrás: pedir la
      // siguiente sería una petición garantizadamente vacía.
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
