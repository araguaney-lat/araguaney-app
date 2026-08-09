// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignCreate _$CampaignCreateFromJson(Map<String, dynamic> json) =>
    CampaignCreate(
      name: json['name'] as String,
      centerIds: (json['center_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      destinationCountry: json['destination_country'] as String?,
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      originCountry: json['origin_country'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
    );

Map<String, dynamic> _$CampaignCreateToJson(CampaignCreate instance) =>
    <String, dynamic>{
      'center_ids': instance.centerIds,
      'description': instance.description,
      'destination_country': instance.destinationCountry,
      'end_date': instance.endDate?.toIso8601String(),
      'name': instance.name,
      'origin_country': instance.originCountry,
      'start_date': instance.startDate?.toIso8601String(),
    };
