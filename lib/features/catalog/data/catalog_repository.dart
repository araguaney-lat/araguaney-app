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

/// How an operation on the catalogue that required the server ended.
///
/// Reading the cached catalogue does not come through here: that is a Drift
/// `Stream` that does not fail. This is for what only the server knows —
/// searching beyond what was downloaded — and for what only the server can
/// authorise.
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

  /// Whether the refusal is «not your place». Creating, editing and promoting
  /// require national administration, so a coordination gets a 403; the
  /// interface does not offer those buttons, and this is the net just in case.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// The catalogue of product types, from the cache first.
///
/// Reading always comes out of Drift; the network only writes. That way a
/// screen paints just as fast with signal and without it, and the place where
/// the catalogue changes is a single one.
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

  /// Fetches the visible catalogue and **replaces** the local one entirely.
  ///
  /// The replacement is the invariant that matters: the local catalogue has to
  /// go on being the one the server accepts. If a product type stopped being
  /// visible for this campaign, offering it without signal would produce a
  /// capture the server is going to refuse when it finally gets sent.
  Future<SyncOutcome> refresh() async {
    try {
      final items = await _productTypes.listProductTypesV1ProductTypesGet();
      await _db.catalogDao.replaceAll(items.map(toProductTypeRow));

      final at = _now();
      await _db.syncMarkersDao.markSynced(SyncResource.productTypes, at);
      return SyncSucceeded(at: at, itemCount: items.length);
    } on Object catch (error) {
      final failure = ApiErrorMapper.fromAny(error);
      // The previous cache stands: why it could not be refreshed is recorded,
      // what was there is not deleted.
      await _db.syncMarkersDao.markFailed(
        SyncResource.productTypes,
        failure.code,
      );
      return SyncFailed(failure);
    }
  }

  /// Searches the **server's** catalogue.
  ///
  /// The cache answers with what was downloaded, which is what is visible for
  /// this campaign and up to the last sync. This answers the rest, and that is
  /// why it is only called when the local one did not suffice: whoever searches
  /// for «paracetamol» and does not see it needs to know whether it does not
  /// exist or is simply not here.
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

  /// The server's record, which is the one that can be fresher than the cache.
  Future<CatalogOutcome<ProductTypeOut>> byId(String id) =>
      _guard(() => _productTypes.getProductTypeV1ProductTypesPtIdGet(ptId: id));

  /// A product's barcodes. There are several on purpose: the same product in
  /// two presentations, or relabelled on import.
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

  /// Accepts into the platform's catalogue a product that belonged to a
  /// campaign.
  ///
  /// The server does it by setting its `campaign_id` to null. It goes apart
  /// from editing because accepting a proposal is a decision, and hiding it
  /// inside a save button would make it invisible.
  Future<CatalogOutcome<ProductTypeOut>> promote(String id) => _write(
    () =>
        _productTypes.promoteProductTypeV1ProductTypesPtIdPromotePost(ptId: id),
  );

  /// Unlinks a barcode from a product.
  ///
  /// It is how a scan that pointed at the wrong thing is corrected. It deletes
  /// neither the product nor the code: it undoes the relation between the two.
  Future<CatalogOutcome<void>> unlinkGtin({
    required String productId,
    required String gtinId,
  }) => _guard(
    () => _productTypes.unlinkProductGtinV1ProductTypesPtIdGtinsGtinIdDelete(
      ptId: productId,
      gtinId: gtinId,
    ),
  );

  /// A write that also leaves the local cache up to date.
  ///
  /// Without this, a freshly created product does not exist for the capture
  /// until the next sync — and it is created exactly when somebody is holding
  /// it and is going to capture it now.
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
