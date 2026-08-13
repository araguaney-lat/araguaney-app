import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/pallet_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/session.dart';
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

/// Si quien tiene la sesión puede modificar tarimas.
///
/// El backend exige rol de coordinación en todas las escrituras de tarima, y
/// **sigue siendo quien decide**: esto solo evita ofrecer un botón que va a
/// responder 403. Si el servidor rechaza igual, su motivo se muestra.
final canOperatePalletsProvider = Provider<bool>((ref) {
  final state = ref.watch(sessionControllerProvider);
  if (state is! SessionActive) return false;
  return const {
    'coordinator',
    'national_admin',
  }.contains(state.session.centerRole);
});
