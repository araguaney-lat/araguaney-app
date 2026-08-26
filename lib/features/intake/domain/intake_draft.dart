import '../../../core/api/generated/models/donor_input.dart';
import '../../../core/api/generated/models/intake_create.dart';
import 'box_draft_input.dart';

/// The donor types the contract recognises.
abstract final class DonorType {
  static const natural = 'fisica';
  static const legal = 'moral';
}

/// A capture under construction.
///
/// It is immutable: every change to the form produces a new capture. That
/// matters more than usual here, because [captureId] has to survive all those
/// edits and all those retries intact.
class IntakeDraft {
  const IntakeDraft({
    required this.captureId,
    this.centerId,
    this.campaignId,
    this.donor,
    this.donorTermsAccepted = false,
    this.donanteLibre,
    this.donationId,
    this.notes,
    this.anonymousExceptionReason,
    this.boxes = const [],
  });

  /// The idempotency key, **generated before the first attempt** and never
  /// regenerated. Retrying a capture is the normal case, not the exception: the
  /// server returns the one it already registered instead of duplicating it.
  final String captureId;

  /// Where this capture is being registered, when the session has to say so.
  ///
  /// It is fixed **when the capture starts** and never resolved again — not
  /// when the queue drains, not on a retry. A national administrator can change
  /// working centre while captures are still waiting for signal, and resolving
  /// this at send time would move donations that were already registered
  /// somewhere else, days after the boxes were physically put down.
  ///
  /// Null for everybody else: the server writes to the centre in their token
  /// and ignores this field, so sending it would only suggest otherwise.
  final String? centerId;

  final String? campaignId;
  final DonorInput? donor;
  final bool donorTermsAccepted;

  /// The donor's loose name, for the operation that does not identify yet.
  final String? donanteLibre;

  /// The pre-registered donation this capture came from, when it was reached
  /// by scanning a `DN-` code.
  final String? donationId;

  final String? notes;

  /// The reason the donation stays anonymous when the server asks for
  /// identification. Whoever captures writes it; the server leaves it under
  /// review.
  final String? anonymousExceptionReason;

  final List<BoxDraftInput> boxes;

  /// With no boxes there is no capture: it is the only field the contract
  /// requires.
  bool get isSubmittable => boxes.isNotEmpty;

  IntakeDraft copyWith({
    String? campaignId,
    DonorInput? donor,
    bool? donorTermsAccepted,
    String? donanteLibre,
    String? donationId,
    String? notes,
    String? anonymousExceptionReason,
    List<BoxDraftInput>? boxes,
  }) => IntakeDraft(
    captureId: captureId,
    centerId: centerId,
    campaignId: campaignId ?? this.campaignId,
    donor: donor ?? this.donor,
    donorTermsAccepted: donorTermsAccepted ?? this.donorTermsAccepted,
    donanteLibre: donanteLibre ?? this.donanteLibre,
    donationId: donationId ?? this.donationId,
    notes: notes ?? this.notes,
    anonymousExceptionReason:
        anonymousExceptionReason ?? this.anonymousExceptionReason,
    boxes: boxes ?? this.boxes,
  );

  /// Removes the identified donor. It goes apart from [copyWith] because
  /// setting a field to null through an optional parameter cannot be told from
  /// leaving it alone.
  IntakeDraft withoutDonor() => IntakeDraft(
    captureId: captureId,
    centerId: centerId,
    campaignId: campaignId,
    donorTermsAccepted: false,
    donanteLibre: donanteLibre,
    donationId: donationId,
    notes: notes,
    anonymousExceptionReason: anonymousExceptionReason,
    boxes: boxes,
  );

  IntakeDraft addBox(BoxDraftInput box) => copyWith(boxes: [...boxes, box]);

  IntakeDraft replaceBox(int index, BoxDraftInput box) => copyWith(
    boxes: [...boxes.sublist(0, index), box, ...boxes.sublist(index + 1)],
  );

  IntakeDraft removeBox(int index) => copyWith(
    boxes: [...boxes.sublist(0, index), ...boxes.sublist(index + 1)],
  );

  IntakeCreate toRequest() => IntakeCreate(
    captureId: captureId,
    centerId: centerId,
    campaignId: campaignId,
    donor: donor,
    donorTermsAccepted: donorTermsAccepted,
    donanteLibre: _trimmedOrNull(donanteLibre),
    donationId: donationId,
    notes: _trimmedOrNull(notes),
    anonymousExceptionReason: _trimmedOrNull(anonymousExceptionReason),
    boxes: boxes.map((box) => box.toRequest()).toList(growable: false),
  );

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
