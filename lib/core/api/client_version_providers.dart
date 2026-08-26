import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'client_version_gate.dart';
import 'generated/rest_client.dart';
import 'update_prompt_memory.dart';

/// What the backend publishes about the versions it supports.
///
/// It goes through the **session-less** `Dio`: the route is public, and asking
/// it from the client that carries a session would tie it to being signed in,
/// which is the opposite of what is needed — somebody blocked by version should
/// not even be able to try to sign in.
final _clientVersionApiProvider = Provider(
  (ref) => RestClient(ref.watch(authDioProvider)).client,
);

/// What has to be known about the version: what state it is in, and which one
/// is the latest published.
///
/// The second is needed to snooze the notice **per version**: without it, one
/// «Más tarde» would silence the next release too.
typedef ClientVersion = ({ClientVersionStatus status, String? latest});

/// The state of the installed version against the one the backend supports.
///
/// **It is asked once per launch and never blocks by failing.** The endpoint is
/// one more request that can time out in a basement, and an application that
/// refuses to open because it could not look up a version is worse than one
/// running slightly behind. With no usable answer the result is
/// [ClientVersionStatus.unknown], which gets in nobody's way.
///
/// The decision of what to do with each state does not live here: this answers
/// what is going on, and `SessionGate` decides what is seen.
final clientVersionStatusProvider = FutureProvider<ClientVersion>((ref) async {
  final installed = ref.watch(appVersionProvider);
  try {
    final published = await ref
        .watch(_clientVersionApiProvider)
        .clientVersionV1ClientVersionGet();
    return (
      status: ClientVersionGate.evaluate(
        currentVersion: installed,
        minSupportedVersion: published.minSupported,
        latestVersion: published.latest,
      ),
      latest: published.latest,
    );
  } on Object {
    // Fails open, on purpose: see above.
    return (status: ClientVersionStatus.unknown, latest: null);
  }
});

/// The memory of the snoozes, so a test does not touch disk.
final updatePromptMemoryProvider = Provider<UpdatePromptMemory>(
  (ref) => const PrefsUpdatePromptMemory(),
);

/// Whether the «there is a new one» notice was already dismissed this launch.
///
/// **It is what keeps the notice at launch and out of the shift.** Without it
/// the notice would come back the moment the session changed state — signing
/// in, changing a forced password — which are exactly the moments when somebody
/// is in the middle of something.
final updatePromptDismissedProvider = StateProvider<bool>((ref) => false);

/// Whether the notice about the latest published version is snoozed.
///
/// It starts as «yes, stay quiet» while it resolves: a notice that flashes on
/// opening and vanishes is worse than one that never shows.
final updateSnoozedProvider = FutureProvider<bool>((ref) async {
  final latest = ref.watch(clientVersionStatusProvider).valueOrNull?.latest;
  if (latest == null) return true;
  return ref
      .watch(updatePromptMemoryProvider)
      .isSnoozed(latest, DateTime.now());
});
