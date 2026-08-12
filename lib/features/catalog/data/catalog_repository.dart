import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/clients/product_types_api.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/sync_markers_dao.dart';
import '../../../core/sync/sync_outcome.dart';
import 'product_type_mapper.dart';

/// Catálogo de tipos de producto, primero desde el cache.
///
/// Leer siempre sale de Drift; la red solo escribe. Así una pantalla se pinta
/// igual de rápido con señal y sin ella, y el sitio donde el catálogo cambia es
/// uno solo.
class CatalogRepository {
  CatalogRepository({
    required ProductTypesApi api,
    required AppDatabase database,
    DateTime Function()? now,
  }) : _productTypes = api,
       _db = database,
       _now = now ?? DateTime.now;

  final ProductTypesApi _productTypes;
  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<List<ProductTypeRow>> watchProductTypes({
    String? category,
    String? search,
  }) => _db.catalogDao.watchAll(category: category, search: search);

  Future<List<String>> categories() => _db.catalogDao.categories();

  Stream<SyncMarkerRow?> watchSyncMarker() =>
      _db.syncMarkersDao.watch(SyncResource.productTypes);

  /// Trae el catálogo visible y **sustituye** el local por completo.
  ///
  /// La sustitución es la invariante que importa: el catálogo local tiene que
  /// seguir siendo el que el servidor acepta. Si un tipo de producto dejó de
  /// ser visible para esta campaña, ofrecerlo sin señal produciría una captura
  /// que el servidor va a rechazar cuando por fin se envíe.
  Future<SyncOutcome> refresh() async {
    try {
      final items = await _productTypes.listProductTypesV1ProductTypesGet();
      await _db.catalogDao.replaceAll(items.map(toProductTypeRow));

      final at = _now();
      await _db.syncMarkersDao.markSynced(SyncResource.productTypes, at);
      return SyncSucceeded(at: at, itemCount: items.length);
    } on Object catch (error) {
      final failure = ApiErrorMapper.fromAny(error);
      // El cache anterior sigue en pie: se registra por qué no se pudo
      // refrescar, no se borra lo que había.
      await _db.syncMarkersDao.markFailed(
        SyncResource.productTypes,
        failure.code,
      );
      return SyncFailed(failure);
    }
  }
}
