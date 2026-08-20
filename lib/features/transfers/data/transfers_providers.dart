import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/transfer_detail_out.dart';
import '../../../core/api/generated/models/transfer_out.dart';
import 'transfers_repository.dart';

final transfersRepositoryProvider = Provider<TransfersRepository>(
  (ref) => TransfersRepository(ref.watch(restClientProvider).transfers),
);

final transfersProvider = FutureProvider<List<TransferOut>>(
  (ref) => ref.watch(transfersRepositoryProvider).list(),
);

final transferDetailProvider = FutureProvider.family<TransferDetailOut, String>(
  (ref, id) => ref.watch(transfersRepositoryProvider).detail(id),
);
