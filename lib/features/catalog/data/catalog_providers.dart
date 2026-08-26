import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/product_gtin_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import 'barcode_lookup.dart';
import 'catalog_repository.dart';

/// Looking a product up by its package's barcode.
final barcodeLookupProvider = Provider<BarcodeLookup>(
  (ref) => BarcodeLookup(
    api: ref.watch(restClientProvider).catalog,
    database: ref.watch(appDatabaseProvider),
  ),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    api: ref.watch(restClientProvider).productTypes,
    database: ref.watch(appDatabaseProvider),
  ),
);

final productTypesProvider =
    StreamProvider.family<List<ProductTypeRow>, String?>(
      (ref, category) => ref
          .watch(catalogRepositoryProvider)
          .watchProductTypes(category: category),
    );

/// A filter over the local catalogue: category, text, or both.
typedef CatalogQuery = ({String? category, String? search});

/// A search in the cached catalogue. It is local, so it answers the same
/// without signal and without spending a request per keystroke.
final catalogSearchProvider =
    StreamProvider.family<List<ProductTypeRow>, CatalogQuery>(
      (ref, query) => ref
          .watch(catalogRepositoryProvider)
          .watchProductTypes(category: query.category, search: query.search),
    );

/// The categories present in the local catalogue, to browse it without typing.
final catalogCategoriesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// Whether this session can add and correct products.
///
/// `product_type.py` requires `require_national_admin` to create, to edit and
/// to promote. Offering the form to somebody who is going to get a 403 is worse
/// than not offering it: whoever captures has another road, which is asking for
/// it.
final canEditCatalogProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);

/// A product's record from the server.
final productRecordProvider =
    FutureProvider.family<CatalogOutcome<ProductTypeOut>, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).byId(id),
    );

/// The barcodes that point at a product.
final productGtinsProvider =
    FutureProvider.family<CatalogOutcome<List<ProductGtinOut>>, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).gtins(id),
    );

/// A search in the server's catalogue.
///
/// It is asked for by hand and not per keystroke: it is one request per search,
/// and the cache already answered while it was being typed. Null while nobody
/// has asked, which is what tells «I did not search» from «I searched and there
/// is nothing».
final serverCatalogSearchProvider =
    FutureProvider.family<CatalogOutcome<List<ProductTypeRow>>, CatalogQuery>(
      (ref, query) => ref
          .watch(catalogRepositoryProvider)
          .search(query.search ?? '', category: query.category),
    );
