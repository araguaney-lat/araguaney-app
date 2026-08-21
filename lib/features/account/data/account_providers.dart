import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import 'account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(restClientProvider).auth),
);

/// El perfil de quien tiene la sesión. Se consulta en línea y no se cachea:
/// enseñar un rol o un centro que dejaron de ser ciertos es peor que decir que
/// no se pudo consultar.
final myAccountProvider = FutureProvider((ref) async {
  final outcome = await ref.watch(accountRepositoryProvider).overview();
  return switch (outcome) {
    AccountDone(:final value) => value,
    AccountRefused(:final failure) => throw failure,
  };
});
