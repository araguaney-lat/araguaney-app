import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/boxes/data/boxes_providers.dart';
import '../../features/catalog/data/catalog_providers.dart';
import '../../features/intake/data/intake_providers.dart';
import '../connectivity/connectivity_controller.dart';
import 'sync_outcome.dart';

/// The only place that decides when the read model is refreshed.
///
/// Repositories do not subscribe to connectivity on their own: if each one
/// reacted, the signal coming back would fire as many bursts as there were open
/// screens, and understanding why a request was made would mean reviewing all
/// of them. Here there is one answer to that question.
class SyncCoordinator {
  SyncCoordinator(this._ref) {
    _ref.onDispose(() => _disposed = true);
  }

  final Ref _ref;
  bool _running = false;

  /// A sync outlives the screen that asked for it: signing out tears the
  /// providers down while the requests are still in flight. Without this flag
  /// the late answer would try to write into a container that no longer
  /// exists.
  bool _disposed = false;

  /// Refreshes the catalogue and the boxes. If a refresh is already running it
  /// does not queue another: when the signal comes back, several signals in a
  /// row are the normal case.
  Future<void> refreshAll() async {
    if (_running || _disposed) return;
    _running = true;
    try {
      final outcomes = await Future.wait([
        _ref.read(catalogRepositoryProvider).refresh(),
        _ref.read(boxesRepositoryProvider).refresh(),
      ]);
      report(outcomes);
      await _flushQueue();
    } finally {
      _running = false;
    }
  }

  /// Flushes the capture queue of whoever has the session open.
  ///
  /// It goes after the refresh and not before: if there is no server, the
  /// refresh already found that out and the flush stops on its first request
  /// without spending more. With no session nothing is flushed: the queue
  /// belongs to one specific person, and without knowing which there is nothing
  /// to send.
  Future<void> _flushQueue() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null || _disposed) return;
    await _ref.read(captureQueueSyncProvider).flush(userId);
  }

  /// Translates what happened in the requests into connection state.
  ///
  /// A refusal from the server (a 403, a 422) **proves there is a server**: it
  /// is reported as online even though the operation failed. Only a network
  /// failure marks it as having no signal.
  void report(List<SyncOutcome> outcomes) {
    if (outcomes.isEmpty || _disposed) return;

    final connectivity = _ref.read(connectivityControllerProvider.notifier);
    final reachable = outcomes.any(
      (outcome) => outcome is! SyncFailed || !outcome.isNetworkFailure,
    );

    reachable
        ? connectivity.reportReachable()
        : connectivity.reportUnreachable();
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);

  // Leaving «sin señal» is the moment worth retrying at. It does not react to
  // every interface change: going from wifi to mobile data while the server is
  // already reachable changes nothing that is on screen.
  ref.listen<ConnectivityStatus>(connectivityControllerProvider, (
    previous,
    next,
  ) {
    if (previous == ConnectivityStatus.offline &&
        next != ConnectivityStatus.offline) {
      coordinator.refreshAll();
    }
  });

  return coordinator;
});
