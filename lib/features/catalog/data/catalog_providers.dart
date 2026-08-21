import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
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
