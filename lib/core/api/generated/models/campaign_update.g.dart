// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignUpdate _$CampaignUpdateFromJson(Map<String, dynamic> json) =>
    CampaignUpdate(
      description: json['description'] as String?,
      destinationCountry: json['destination_country'] as String?,
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool?,
      name: json['name'] as String?,
      originCountry: json['origin_country'] as String?,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      weightGoalKg: json['weight_goal_kg'],
    );

Map<String, dynamic> _$CampaignUpdateToJson(CampaignUpdate instance) =>
    <String, dynamic>{
      'description': instance.description,
      'destination_country': instance.destinationCountry,
      'end_date': instance.endDate?.toIso8601String(),
      'is_active': instance.isActive,
      'name': instance.name,
      'origin_country': instance.originCountry,
      'start_date': instance.startDate?.toIso8601String(),
      'weight_goal_kg': instance.weightGoalKg,
    };
