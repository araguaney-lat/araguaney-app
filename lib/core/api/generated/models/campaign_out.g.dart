// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignOut _$CampaignOutFromJson(Map<String, dynamic> json) => CampaignOut(
  createdAt: DateTime.parse(json['created_at'] as String),
  description: json['description'] as String?,
  destinationCountry: json['destination_country'] as String?,
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  id: json['id'] as String,
  isActive: json['is_active'] as bool,
  isGeneral: json['is_general'] as bool,
  name: json['name'] as String,
  originCountry: json['origin_country'] as String?,
  slug: json['slug'] as String?,
  startDate: json['start_date'] == null
      ? null
      : DateTime.parse(json['start_date'] as String),
  weightGoalKg: json['weight_goal_kg'] as String?,
);

Map<String, dynamic> _$CampaignOutToJson(CampaignOut instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'destination_country': instance.destinationCountry,
      'end_date': instance.endDate?.toIso8601String(),
      'id': instance.id,
      'is_active': instance.isActive,
      'is_general': instance.isGeneral,
      'name': instance.name,
      'origin_country': instance.originCountry,
      'slug': instance.slug,
      'start_date': instance.startDate?.toIso8601String(),
      'weight_goal_kg': instance.weightGoalKg,
    };
