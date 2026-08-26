import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(restClientProvider).auth),
);

/// The profile of whoever holds the session. It is looked up online and not
/// cached: showing a role or a centre that stopped being true is worse than
/// saying it could not be looked up.
final myAccountProvider = FutureProvider((ref) async {
  final outcome = await ref.watch(accountRepositoryProvider).overview();
  return switch (outcome) {
    AccountDone(:final value) => value,
    AccountRefused(:final failure) => throw failure,
  };
});
