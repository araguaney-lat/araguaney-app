import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/product_types_api.dart';
import '../../../core/api/generated/models/product_gtin_out.dart';
import '../../../core/api/generated/models/product_type_create.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/api/generated/models/product_type_update.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/sync_markers_dao.dart';
import '../../../core/sync/sync_outcome.dart';
import 'product_type_mapper.dart';

/// Cómo terminó una operación sobre el catálogo que exigió el servidor.
///
/// Leer el catálogo cacheado no pasa por aquí: eso es un `Stream` de Drift que
/// no falla. Esto es para lo que solo el servidor sabe —buscar más allá de lo
/// descargado— y para lo que solo el servidor puede autorizar.
sealed class CatalogOutcome<T> {
  const CatalogOutcome();
}

final class CatalogDone<T> extends CatalogOutcome<T> {
  const CatalogDone(this.value);

  final T value;
}

final class CatalogRefused<T> extends CatalogOutcome<T> {
  const CatalogRefused(this.failure);

  final ApiFailure failure;

  /// Si el rechazo es «no te toca». Crear, editar y promover exigen
  /// administración nacional, así que una coordinación recibe un 403; la
  /// interfaz no ofrece esos botones, y esto es la red por si acaso.
  bool get isForbidden => failure is ForbiddenFailure;
}

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

  /// Busca en el catálogo **del servidor**.
  ///
  /// El cache responde lo que se descargó, que es lo visible para esta campaña
  /// y hasta la última sincronización. Esto responde el resto, y por eso solo
  /// se llama cuando lo local no alcanza: quien busca «paracetamol» y no lo ve
  /// necesita saber si no existe o si no está aquí.
  Future<CatalogOutcome<List<ProductTypeRow>>> search(
    String query, {
    String? category,
  }) => _guard(() async {
    final items = await _productTypes.searchProductTypesV1ProductTypesSearchGet(
      q: query,
      category: category,
    );
    return items.map(toProductTypeRow).toList(growable: false);
  });

  /// La ficha del servidor, que es la que puede estar más fresca que el cache.
  Future<CatalogOutcome<ProductTypeOut>> byId(String id) =>
      _guard(() => _productTypes.getProductTypeV1ProductTypesPtIdGet(ptId: id));

  /// Los códigos de barras de un producto. Son varios a propósito: el mismo
  /// producto en dos presentaciones, o reetiquetado en la importación.
  Future<CatalogOutcome<List<ProductGtinOut>>> gtins(String id) => _guard(
    () => _productTypes.listProductGtinsV1ProductTypesPtIdGtinsGet(ptId: id),
  );

  Future<CatalogOutcome<ProductTypeOut>> create(ProductTypeCreate data) =>
      _write(
        () => _productTypes.createProductTypeV1ProductTypesPost(body: data),
      );

  Future<CatalogOutcome<ProductTypeOut>> update(
    String id,
    ProductTypeUpdate data,
  ) => _write(
    () => _productTypes.updateProductTypeV1ProductTypesPtIdPatch(
      ptId: id,
      body: data,
    ),
  );

  /// Acepta en el catálogo de la plataforma un producto que era de una campaña.
  ///
  /// El servidor lo hace poniendo su `campaign_id` en nulo. Va aparte de editar
  /// porque aceptar una propuesta es una decisión, y esconderla dentro de un
  /// botón de guardar la haría invisible.
  Future<CatalogOutcome<ProductTypeOut>> promote(String id) => _write(
    () =>
        _productTypes.promoteProductTypeV1ProductTypesPtIdPromotePost(ptId: id),
  );

  /// Desliga un código de barras de un producto.
  ///
  /// Es como se corrige un escaneo que apuntaba a lo que no era. No borra el
  /// producto ni el código: deshace la relación entre los dos.
  Future<CatalogOutcome<void>> unlinkGtin({
    required String productId,
    required String gtinId,
  }) => _guard(
    () => _productTypes.unlinkProductGtinV1ProductTypesPtIdGtinsGtinIdDelete(
      ptId: productId,
      gtinId: gtinId,
    ),
  );

  /// Una escritura que además deja el cache local al día.
  ///
  /// Sin esto, un producto recién creado no existe para la captura hasta la
  /// siguiente sincronización — y se crea justo cuando alguien lo tiene en la
  /// mano y lo va a capturar ahora.
  Future<CatalogOutcome<ProductTypeOut>> _write(
    Future<ProductTypeOut> Function() call,
  ) async {
    final outcome = await _guard(call);
    if (outcome case CatalogDone(:final value)) {
      await _db.catalogDao.upsert(toProductTypeRow(value));
    }
    return outcome;
  }

  Future<CatalogOutcome<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return CatalogDone(await call());
    } on Object catch (error) {
      return CatalogRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
