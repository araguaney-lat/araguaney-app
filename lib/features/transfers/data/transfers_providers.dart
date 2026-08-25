import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/transfer_detail_out.dart';
import '../../../core/api/generated/models/transfer_out.dart';
import '../../../core/center/center_providers.dart';
import 'transfers_repository.dart';

final transfersRepositoryProvider = Provider<TransfersRepository>(
  (ref) => TransfersRepository(ref.watch(restClientProvider).transfers),
);

/// The transfers that touch the working centre, in either direction.
///
/// Both ends count: a transfer is this centre's business whether it is leaving
/// or arriving, and those are the two things somebody here can act on. A
/// session that belongs to a centre gets this from the server and is left
/// alone.
final transfersProvider = FutureProvider<List<TransferOut>>((ref) async {
  final transfers = await ref.watch(transfersRepositoryProvider).list();
  final center = ref.watch(writeCenterIdProvider);
  if (center == null) return transfers;
  return transfers
      .where(
        (transfer) =>
            transfer.fromCenterId == center || transfer.toCenterId == center,
      )
      .toList(growable: false);
});

final transferDetailProvider = FutureProvider.family<TransferDetailOut, String>(
  (ref, id) => ref.watch(transfersRepositoryProvider).detail(id),
);
