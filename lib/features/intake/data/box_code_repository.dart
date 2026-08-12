import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/boxes_api.dart';
import '../../../core/api/generated/models/box_code_reserve_in.dart';
import '../../../core/db/app_database.dart';
import '../../../core/sync/sync_outcome.dart';

/// Códigos de caja apartados con señal para gastarse sin ella.
///
/// Sin código no hay etiqueta imprimible, y en un centro con prisa nadie vuelve
/// a tocar una caja ya cerrada para etiquetarla después: o sale con su etiqueta
/// o sale sin ella para siempre. Por eso el bloque se pide **antes** de bajar
/// al sótano, que es el único momento en que se puede pedir.
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

  Stream<int> watchAvailable(String userId) =>
      _db.boxCodesDao.watchAvailable(userId);

  /// Pide un bloque al servidor y lo guarda.
  ///
  /// Cuántos códigos caben en una petición lo decide el backend; aquí no se
  /// replica ese límite. Si pide de más, contesta y esta capa muestra su
  /// motivo.
  Future<SyncOutcome> topUp({
    required int count,
    required String userId,
  }) async {
    try {
      final block = await _boxesApi.reserveBoxCodesV1BoxesCodesReservePost(
        body: BoxCodeReserveIn(count: count),
      );
      await _db.boxCodesDao.store(block.codes, userId: userId, at: _now());
      return SyncSucceeded(at: _now(), itemCount: block.codes.length);
    } on Object catch (error) {
      return SyncFailed(ApiErrorMapper.fromAny(error));
    }
  }

  /// Toma códigos del bloque local para una captura sin señal.
  ///
  /// Puede devolver menos de los pedidos. Quedarse sin códigos no impide
  /// capturar —perder la captura sería mucho peor—, solo impide etiquetar esas
  /// cajas hasta que la captura llegue al servidor.
  Future<List<String>> take(int count, {required String userId}) =>
      _db.boxCodesDao.take(count, userId: userId, at: _now());
}
