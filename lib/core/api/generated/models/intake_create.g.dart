// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntakeCreate _$IntakeCreateFromJson(Map<String, dynamic> json) => IntakeCreate(
  boxes: (json['boxes'] as List<dynamic>)
      .map((e) => BoxDraft.fromJson(e as Map<String, dynamic>))
      .toList(),
  donorTermsAccepted: json['donor_terms_accepted'] as bool? ?? false,
  anonymousExceptionReason: json['anonymous_exception_reason'] as String?,
  campaignId: json['campaign_id'] as String?,
  captureId: json['capture_id'] as String?,
  centerId: json['center_id'] as String?,
  donanteLibre: json['donante_libre'] as String?,
  donationId: json['donation_id'] as String?,
  donor: json['donor'] == null
      ? null
      : DonorInput.fromJson(json['donor'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$IntakeCreateToJson(IntakeCreate instance) =>
    <String, dynamic>{
      'anonymous_exception_reason': instance.anonymousExceptionReason,
      'boxes': instance.boxes,
      'campaign_id': instance.campaignId,
      'capture_id': instance.captureId,
      'center_id': instance.centerId,
      'donante_libre': instance.donanteLibre,
      'donation_id': instance.donationId,
      'donor': instance.donor,
      'donor_terms_accepted': instance.donorTermsAccepted,
      'notes': instance.notes,
    };
