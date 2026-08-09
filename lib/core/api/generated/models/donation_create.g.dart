// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationCreate _$DonationCreateFromJson(Map<String, dynamic> json) =>
    DonationCreate(
      donor: DonorInput.fromJson(json['donor'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => DonationItemInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      intendedCampaignId: json['intended_campaign_id'] as String?,
      intendedCenterId: json['intended_center_id'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$DonationCreateToJson(DonationCreate instance) =>
    <String, dynamic>{
      'donor': instance.donor,
      'intended_campaign_id': instance.intendedCampaignId,
      'intended_center_id': instance.intendedCenterId,
      'items': instance.items,
      'notes': instance.notes,
      'terms_accepted': instance.termsAccepted,
    };
