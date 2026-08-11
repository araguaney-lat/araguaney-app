import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/boxes_dao.dart';
import '../../../core/db/db_providers.dart';
import 'boxes_repository.dart';

final boxesRepositoryProvider = Provider<BoxesRepository>(
  (ref) => BoxesRepository(
    api: ref.watch(restClientProvider).boxes,
    database: ref.watch(appDatabaseProvider),
  ),
);

final boxesProvider = StreamProvider<List<BoxWithProduct>>(
  (ref) => ref.watch(boxesRepositoryProvider).watchBoxes(),
);

final boxProvider = StreamProvider.family<BoxWithProduct?, String>(
  (ref, id) => ref.watch(boxesRepositoryProvider).watchBox(id),
);

/// Cuándo se refrescaron las cajas por última vez. La interfaz lo convierte en
/// «datos de hace 12 minutos».
final boxesSyncMarkerProvider = StreamProvider<SyncMarkerRow?>(
  (ref) => ref.watch(boxesRepositoryProvider).watchSyncMarker(),
);
