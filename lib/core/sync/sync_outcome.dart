import '../api/api_failure.dart';

/// The result of refreshing a cached resource.
///
/// A refresh **never throws** towards the interface. The screen already has
/// data to show; what it needs to know is whether it is still the latest and,
/// if not, why. Returning it as a value forces the decision at each site
/// instead of letting an exception take the screen down with it.
sealed class SyncOutcome {
  const SyncOutcome();
}

final class SyncSucceeded extends SyncOutcome {
  const SyncSucceeded({required this.at, required this.itemCount});

  final DateTime at;
  final int itemCount;
}

final class SyncFailed extends SyncOutcome {
  const SyncFailed(this.failure);

  final ApiFailure failure;

  /// Whether the failure was a network one. The connection state uses it: a
  /// refusal from the server proves the server is there, and must not be marked
  /// as having no signal.
  bool get isNetworkFailure => failure is NetworkFailure;
}
