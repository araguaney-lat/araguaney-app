// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationOut _$DonationOutFromJson(Map<String, dynamic> json) => DonationOut(
  code: json['code'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  id: json['id'] as String,
  intendedCampaignId: json['intended_campaign_id'] as String?,
  intendedCenterId: json['intended_center_id'] as String?,
  notes: json['notes'] as String?,
  receivedCenterId: json['received_center_id'] as String?,
  registeredAt: json['registered_at'] == null
      ? null
      : DateTime.parse(json['registered_at'] as String),
  status: json['status'] as String,
  atypicalVolume: json['atypical_volume'] as bool? ?? false,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => DonationItemOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  photos:
      (json['photos'] as List<dynamic>?)
          ?.map((e) => DonationPhotoOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$DonationOutToJson(DonationOut instance) =>
    <String, dynamic>{
      'atypical_volume': instance.atypicalVolume,
      'code': instance.code,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'intended_campaign_id': instance.intendedCampaignId,
      'intended_center_id': instance.intendedCenterId,
      'items': instance.items,
      'notes': instance.notes,
      'photos': instance.photos,
      'received_center_id': instance.receivedCenterId,
      'registered_at': instance.registeredAt?.toIso8601String(),
      'status': instance.status,
    };
