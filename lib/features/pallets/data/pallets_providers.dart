import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/pallet_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'pallets_repository.dart';

final palletsRepositoryProvider = Provider<PalletsRepository>(
  (ref) => PalletsRepository(ref.watch(restClientProvider).pallets),
);

final palletsProvider = FutureProvider<List<PalletOut>>(
  (ref) => ref.watch(palletsRepositoryProvider).list(),
);

final palletDetailProvider = FutureProvider.family<PalletDetailOut, String>(
  (ref, id) => ref.watch(palletsRepositoryProvider).detail(id),
);

/// Si quien tiene la sesión puede modificar tarimas. El backend exige
/// coordinación en todas las escrituras de tarima.
final canOperatePalletsProvider = Provider<bool>(
  (ref) => ref.watch(isCenterCoordinatorProvider),
);
