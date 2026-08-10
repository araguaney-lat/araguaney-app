import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import 'catalog_repository.dart';

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
