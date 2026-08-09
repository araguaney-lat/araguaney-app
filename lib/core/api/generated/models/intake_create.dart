// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'box_draft.dart';
import 'donor_input.dart';

part 'intake_create.g.dart';

@JsonSerializable()
class IntakeCreate {
  const IntakeCreate({
    required this.boxes,
    this.donorTermsAccepted = false,
    this.anonymousExceptionReason,
    this.campaignId,
    this.captureId,
    this.centerId,
    this.donanteLibre,
    this.donationId,
    this.donor,
    this.notes,
  });

  factory IntakeCreate.fromJson(Map<String, Object?> json) =>
      _$IntakeCreateFromJson(json);

  @JsonKey(name: 'anonymous_exception_reason')
  final String? anonymousExceptionReason;
  final List<BoxDraft> boxes;
  @JsonKey(name: 'campaign_id')
  final String? campaignId;
  @JsonKey(name: 'capture_id')
  final String? captureId;
  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'donante_libre')
  final String? donanteLibre;
  @JsonKey(name: 'donation_id')
  final String? donationId;
  final DonorInput? donor;
  @JsonKey(name: 'donor_terms_accepted')
  final bool donorTermsAccepted;
  final String? notes;

  Map<String, Object?> toJson() => _$IntakeCreateToJson(this);
}
