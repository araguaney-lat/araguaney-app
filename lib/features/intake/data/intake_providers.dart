import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/donor_input.dart';
import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import '../domain/box_draft_input.dart';
import '../domain/intake_draft.dart';
import 'box_code_repository.dart';
import 'capture_queue_repository.dart';
import 'capture_queue_sync.dart';
import 'intake_repository.dart';

/// Where the idempotency key comes from. It is a provider so a test can pin it
/// and check that it does not change between retries.
final captureIdGeneratorProvider = Provider<String Function()>(
  (ref) => const Uuid().v4,
);

final intakeRepositoryProvider = Provider<IntakeRepository>(
  (ref) => IntakeRepository(ref.watch(restClientProvider).intakes),
);

/// Who has the session open. The queue and the reserved codes are theirs and
/// nobody else's, so everything that touches them goes through here.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionUserIdProvider),
);

final captureQueueRepositoryProvider = Provider<CaptureQueueRepository>(
  (ref) => CaptureQueueRepository(database: ref.watch(appDatabaseProvider)),
);

final captureQueueSyncProvider = Provider<CaptureQueueSync>(
  (ref) => CaptureQueueSync(
    api: ref.watch(restClientProvider).intakes,
    database: ref.watch(appDatabaseProvider),
  ),
);

final boxCodeRepositoryProvider = Provider<BoxCodeRepository>(
  (ref) => BoxCodeRepository(
    api: ref.watch(restClientProvider).boxes,
    database: ref.watch(appDatabaseProvider),
  ),
);

/// How many of this person's captures are waiting for signal. Zero when there
/// is no session: without knowing whose the queue is, there is no queue to
/// show.
final pendingCaptureCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return ref.watch(captureQueueRepositoryProvider).watchPendingCount(userId);
});

final queuedCapturesProvider = StreamProvider<List<QueuedCaptureRow>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(captureQueueRepositoryProvider).watchAll(userId);
});

/// Unspent box codes this person has left on the device.
///
/// Counted for the centre being worked in: a block reserved for another one is
/// not going to label anything here, and counting it would promise a box's
/// worth of labels that do not exist.
final availableBoxCodesProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);
  return ref
      .watch(boxCodeRepositoryProvider)
      .watchAvailable(userId, centerId: ref.watch(writeCenterIdProvider));
});

/// The campaigns whoever holds the session takes part in. They are looked up
/// online: choosing a campaign is part of the write path, which in this phase
/// requires signal anyway.
final myCampaignsProvider = FutureProvider<List<CampaignOut>>(
  (ref) => ref
      .watch(restClientProvider)
      .campaigns
      .listMyCampaignsV1CampaignsMineGet(),
);

/// The centre's registered captures. They are looked up online: the offline
/// read the operation needs is the inventory's, not the history's.
///
/// Narrowed to the working centre when the session has one: the count of what
/// was registered today answers «how is this centre doing», and the country's
/// total is a different question with its own screen.
final intakesProvider = FutureProvider<List<IntakeOut>>((ref) async {
  final intakes = await ref.watch(intakeRepositoryProvider).list();
  final center = ref.watch(writeCenterIdProvider);
  if (center == null) return intakes;
  return intakes
      .where((intake) => intake.centerId == center)
      .toList(growable: false);
});

/// The owner of the capture form.
///
/// It is discarded when the screen closes, and with it the idempotency key: the
/// next capture is another capture. While the screen lives, that key changes
/// for nothing — not on an edit, not on a failure, not on a retry — which is
/// the offline queue's first invariant.
class IntakeDraftController extends AutoDisposeNotifier<IntakeDraft> {
  /// The working centre is read **once, here**, with the same `read` and for
  /// the same reason as the idempotency key: both identify what this capture
  /// is, and neither may change while it is being written or waiting to be
  /// sent.
  @override
  IntakeDraft build() => IntakeDraft(
    captureId: ref.read(captureIdGeneratorProvider)(),
    centerId: ref.read(writeCenterIdProvider),
  );

  void setCampaign(String? campaignId) =>
      state = state.copyWith(campaignId: campaignId);

  void setDonor(DonorInput donor, {required bool termsAccepted}) =>
      state = state.copyWith(donor: donor, donorTermsAccepted: termsAccepted);

  void clearDonor() => state = state.withoutDonor();

  void setDonanteLibre(String? value) =>
      state = state.copyWith(donanteLibre: value);

  void setNotes(String? value) => state = state.copyWith(notes: value);

  void setExceptionReason(String? reason) =>
      state = state.copyWith(anonymousExceptionReason: reason);

  void addBox(BoxDraftInput box) => state = state.addBox(box);

  void replaceBox(int index, BoxDraftInput box) =>
      state = state.replaceBox(index, box);

  void removeBox(int index) => state = state.removeBox(index);

  /// Fills in from a pre-registered donation.
  ///
  /// It only ties the capture to the donation. The items the donor declared do
  /// not turn into boxes automatically: they are what they said they were
  /// bringing, and what gets registered is what arrived. Confusing the two
  /// would be inventing inventory.
  void prefillFromDonation(String donationId) =>
      state = state.copyWith(donationId: donationId);

  /// Assigns reserved codes to the boxes that do not have one yet.
  ///
  /// It is called right before queueing: a box captured without signal needs
  /// its code at that moment, because nobody is going to reopen a sealed box to
  /// label it later. If the block does not stretch, the remaining boxes are
  /// left without a code and the server assigns it when the capture arrives.
  void assignCodes(List<String> codes) {
    var next = 0;
    state = state.copyWith(
      boxes: [
        for (final box in state.boxes)
          if (box.code == null && next < codes.length)
            box.copyWith(code: codes[next++])
          else
            box,
      ],
    );
  }

  Future<IntakeSubmission> submit() =>
      ref.read(intakeRepositoryProvider).submit(state);

  /// Stores the capture to be sent when there is signal.
  Future<void> enqueue(String userId) => ref
      .read(captureQueueRepositoryProvider)
      .enqueue(draft: state, userId: userId);
}

final intakeDraftControllerProvider =
    AutoDisposeNotifierProvider<IntakeDraftController, IntakeDraft>(
      IntakeDraftController.new,
    );
