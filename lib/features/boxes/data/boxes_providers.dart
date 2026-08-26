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

/// When the boxes were last refreshed. The interface turns it into
/// «datos de hace 12 minutos».
final boxesSyncMarkerProvider = StreamProvider<SyncMarkerRow?>(
  (ref) => ref.watch(boxesRepositoryProvider).watchSyncMarker(),
);

/// A box's journey: who sealed it, when it went onto a pallet, when it left. It
/// answers «¿qué le pasó a esto?» about the object somebody is holding, which
/// is the question asked in the bad moments.
final boxEventsProvider = FutureProvider.family<List<QrEventOut>, String>(
  (ref, boxId) => ref
      .watch(restClientProvider)
      .boxes
      .listBoxEventsV1BoxesBoxIdEventsGet(boxId: boxId),
);
