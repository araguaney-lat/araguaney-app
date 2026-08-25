import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/pallet_out.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/center/center_providers.dart';
import 'pallets_repository.dart';

final palletsRepositoryProvider = Provider<PalletsRepository>(
  (ref) => PalletsRepository(ref.watch(restClientProvider).pallets),
);

/// Las tarimas que se ven, que son las del centro en el que se trabaja.
///
/// The server scopes this by itself for a session that belongs to a centre.
/// A national administrator receives every centre's, and coordinating a pallet
/// in the country's list would mean deciding about boxes nobody in the room can
/// see.
final palletsProvider = FutureProvider<List<PalletOut>>((ref) async {
  final pallets = await ref.watch(palletsRepositoryProvider).list();
  final center = ref.watch(writeCenterIdProvider);
  if (center == null) return pallets;
  return pallets
      .where((pallet) => pallet.centerId == center)
      .toList(growable: false);
});

final palletDetailProvider = FutureProvider.family<PalletDetailOut, String>(
  (ref, id) => ref.watch(palletsRepositoryProvider).detail(id),
);

/// Si quien tiene la sesión puede modificar tarimas. El backend exige
/// coordinación en todas las escrituras de tarima.
final canOperatePalletsProvider = Provider<bool>(
  (ref) => ref.watch(isCenterCoordinatorProvider),
);

/// El recorrido de una tarima, por lo mismo que el de una caja.
final palletEventsProvider = FutureProvider.family<List<QrEventOut>, String>(
  (ref, palletId) => ref
      .watch(restClientProvider)
      .pallets
      .listPalletEventsV1PalletsPalletIdEventsGet(palletId: palletId),
);
