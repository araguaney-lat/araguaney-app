import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/request_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'requests_repository.dart';

final requestsRepositoryProvider = Provider<RequestsRepository>(
  (ref) => RequestsRepository(ref.watch(restClientProvider).requests),
);

/// The board, whole.
///
/// It is asked for without a status filter even though the endpoint accepts
/// one: the screen shows how many are open, and asking for both halves
/// separately would spend two requests to answer one question.
final requestsBoardProvider = FutureProvider<RequestsOutcome<List<RequestOut>>>(
  (ref) => ref.watch(requestsRepositoryProvider).list(),
);

/// One request with its thread. The record asks again instead of reusing the
/// row from the list: a thread moves while somebody is reading it.
final requestRecordProvider =
    FutureProvider.family<RequestsOutcome<RequestOut>, String>(
      (ref, id) => ref.watch(requestsRepositoryProvider).one(id),
    );

/// What the platform has of what a request asks for. An empty list is the
/// normal answer, so this never fails.
final requestMatchesProvider =
    FutureProvider.family<List<RequestMatch>, String>(
      (ref, id) => ref.watch(requestsRepositoryProvider).matches(id),
    );

/// Whether this session can move a request's status. The backend requires
/// national administration on that route and on no other of the board.
final canMoveRequestStatusProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);
