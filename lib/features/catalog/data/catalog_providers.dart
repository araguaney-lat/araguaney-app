import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/product_gtin_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import 'barcode_lookup.dart';
import 'catalog_repository.dart';

/// Buscar un producto por el código de barras de su envase.
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

/// Filtro del catálogo local: categoría, texto, o ambos.
typedef CatalogQuery = ({String? category, String? search});

/// Búsqueda en el catálogo cacheado. Es local, así que responde igual sin
/// señal y sin gastar una petición por tecla.
final catalogSearchProvider =
    StreamProvider.family<List<ProductTypeRow>, CatalogQuery>(
      (ref, query) => ref
          .watch(catalogRepositoryProvider)
          .watchProductTypes(category: query.category, search: query.search),
    );

/// Categorías presentes en el catálogo local, para navegarlo sin teclear.
final catalogCategoriesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

/// Si esta sesión puede dar de alta y corregir productos.
///
/// `product_type.py` exige `require_national_admin` en crear, editar y
/// promover. Ofrecerle el formulario a quien va a recibir un 403 es peor que
/// no ofrecerlo: quien captura tiene otro camino, que es pedirlo.
final canEditCatalogProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);

/// La ficha del servidor de un producto.
final productRecordProvider =
    FutureProvider.family<CatalogOutcome<ProductTypeOut>, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).byId(id),
    );

/// Los códigos de barras que apuntan a un producto.
final productGtinsProvider =
    FutureProvider.family<CatalogOutcome<List<ProductGtinOut>>, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).gtins(id),
    );

/// Búsqueda en el catálogo del servidor.
///
/// Se pide a mano y no por tecla: es una petición por búsqueda, y el cache ya
/// respondió mientras se escribía. Nulo mientras nadie la pidió, que es lo que
/// distingue «no busqué» de «busqué y no hay».
final serverCatalogSearchProvider =
    FutureProvider.family<CatalogOutcome<List<ProductTypeRow>>, CatalogQuery>(
      (ref, query) => ref
          .watch(catalogRepositoryProvider)
          .search(query.search ?? '', category: query.category),
    );
