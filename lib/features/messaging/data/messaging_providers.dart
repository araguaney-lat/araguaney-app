import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/thread_detail_out.dart';
import '../../../core/api/generated/models/thread_out.dart';
import 'messaging_repository.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepository(ref.watch(restClientProvider).messages),
);

final threadsProvider = FutureProvider<List<ThreadOut>>(
  (ref) => ref.watch(messagingRepositoryProvider).threads(),
);

final threadProvider = FutureProvider.family<ThreadDetailOut, String>(
  (ref, id) => ref.watch(messagingRepositoryProvider).thread(id),
);

/// Unread private messages. It feeds the entry point on the main screen.
final unreadMessagesProvider = FutureProvider<int>(
  (ref) => ref.watch(messagingRepositoryProvider).unreadCount(),
);
