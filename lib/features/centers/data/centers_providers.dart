import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/center_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'centers_repository.dart';

final centersRepositoryProvider = Provider<CentersRepository>(
  (ref) => CentersRepository(ref.watch(restClientProvider).centers),
);

/// The centres, for whoever can list them.
///
/// It is asked for once and reused: it is a short list that changes little, and
/// whoever looks at it is usually resolving several identifiers in a row — the
/// rows of a transfers list, for instance.
final centersProvider = FutureProvider<CentersOutcome<List<CenterOut>>>(
  (ref) => ref.watch(centersRepositoryProvider).list(),
);

/// Centre names by identifier, or empty if this session cannot resolve them.
///
/// **Empty is not an error.** Listing centres requires national administration,
/// so for a coordination this will always be empty and the interface has to
/// behave exactly as before: no name, no gap and no apology. It is what request
/// 3 asks to fix properly, by adding the names to the transfer's contract; this
/// only stops staying quiet for whoever can look them up.
final centerNamesProvider = Provider<Map<String, String>>((ref) {
  final centers = ref.watch(centersProvider).valueOrNull;
  return switch (centers) {
    CentersRead(:final value) => {
      for (final center in value) center.id: center.name,
    },
    _ => const {},
  };
});

/// Whether this session can ask for the list. The backend requires national
/// administration on both centre endpoints.
final canListCentersProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);

/// A particular centre's record.
final centerRecordProvider =
    FutureProvider.family<CentersOutcome<CenterOut>, String>(
      (ref, id) => ref.watch(centersRepositoryProvider).byId(id),
    );
