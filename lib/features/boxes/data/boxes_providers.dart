import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/center/center_providers.dart';
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
  (ref) => ref
      .watch(boxesRepositoryProvider)
      .watchBoxes(centerId: ref.watch(writeCenterIdProvider)),
);

final boxProvider = StreamProvider.family<BoxWithProduct?, String>(
  (ref, id) => ref.watch(boxesRepositoryProvider).watchBox(id),
);

/// Cuándo se refrescaron las cajas por última vez. La interfaz lo convierte en
/// «datos de hace 12 minutos».
final boxesSyncMarkerProvider = StreamProvider<SyncMarkerRow?>(
  (ref) => ref.watch(boxesRepositoryProvider).watchSyncMarker(),
);

/// El recorrido de una caja: quién la selló, cuándo entró en una tarima, cuándo
/// salió. Responde «¿qué le pasó a esto?» sobre el objeto que alguien tiene en
/// la mano, que es la pregunta que se hace en los malos momentos.
final boxEventsProvider = FutureProvider.family<List<QrEventOut>, String>(
  (ref, boxId) => ref
      .watch(restClientProvider)
      .boxes
      .listBoxEventsV1BoxesBoxIdEventsGet(boxId: boxId),
);
