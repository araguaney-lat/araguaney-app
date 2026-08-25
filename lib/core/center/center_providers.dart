import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'working_center.dart';
import 'working_center_memory.dart';

/// The memory of the choice, as a provider so a test never touches disk.
final workingCenterMemoryProvider = Provider<WorkingCenterMemory>(
  (ref) => const PrefsWorkingCenterMemory(),
);

/// The centre a national administrator is operating in, once it is known.
///
/// It is asynchronous because it is read back from the device: while that read
/// is in flight nothing decides anything, which is what keeps the application
/// from flashing the chooser at somebody who already chose.
class WorkingCenterController extends AsyncNotifier<WorkingCenter?> {
  @override
  Future<WorkingCenter?> build() async {
    final userId = ref.watch(sessionUserIdProvider);
    if (userId == null) return null;
    return ref.watch(workingCenterMemoryProvider).read(userId);
  }

  /// Records the choice. It is written before the state changes, so a restart
  /// right afterwards finds the same centre the screen is already showing.
  Future<void> choose(WorkingCenter center) async {
    final userId = ref.read(sessionUserIdProvider);
    if (userId == null) return;
    await ref.read(workingCenterMemoryProvider).write(userId, center);
    state = AsyncData(center);
  }
}

final workingCenterProvider =
    AsyncNotifierProvider<WorkingCenterController, WorkingCenter?>(
      WorkingCenterController.new,
    );

/// The centre a create request has to name, or null when the server decides.
///
/// Null is not «no centre»: it means the request leaves the field out, and the
/// backend fills it with the one in the token. Sending a centre from a session
/// that has one is pointless — `resolve_write_center_id` ignores it — and it
/// would suggest a coordinator can write somewhere they cannot.
///
/// **The same value narrows what is read.** A national administrator receives
/// every centre's pallets and shipments from the server, so the lists filter by
/// this; for everybody else it is null and nothing is filtered, because the
/// server already did it. Writing into one centre while reading the whole
/// country would be two different places on the same screen.
final writeCenterIdProvider = Provider<String?>((ref) {
  if (!ref.watch(isNationalAdminProvider)) return null;
  return ref.watch(workingCenterProvider).valueOrNull?.id;
});

/// The centre this session acts as, however it got one.
///
/// The token's centre, and the chosen one when the token carries none. It
/// answers «which centre is mine, right now»: whose team directory to show,
/// and whether a transfer is arriving or leaving. Before this, a national
/// administrator answered null to that question and got a directory of nobody
/// and a transfer with no direction.
final actingCenterIdProvider = Provider<String?>(
  (ref) =>
      ref.watch(myCenterIdProvider) ??
      ref.watch(workingCenterProvider).valueOrNull?.id,
);

/// Whether the chosen centre is still being read from the device.
///
/// The gate waits on this instead of showing the application for the instant
/// the read takes: what it would show is the home screen, which asks the server
/// for a dashboard and then gets thrown away.
final workingCenterPendingProvider = Provider<bool>((ref) {
  if (!ref.watch(isNationalAdminProvider)) return false;
  final center = ref.watch(workingCenterProvider);
  return center.isLoading && !center.hasValue;
});

/// Whether the application has to ask for a centre before anything else.
///
/// Not while the read is still in flight — «not loaded yet» and «never chose»
/// are different things, and only one of them is a question. A read that
/// **fails** counts as a question: asking again is tedious and never wrong,
/// while assuming a centre would write somewhere nobody named.
final needsWorkingCenterProvider = Provider<bool>((ref) {
  if (!ref.watch(isNationalAdminProvider)) return false;
  if (ref.watch(workingCenterPendingProvider)) return false;
  return ref.watch(workingCenterProvider).valueOrNull == null;
});
