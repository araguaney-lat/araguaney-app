// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_weight_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignWeightOut _$CampaignWeightOutFromJson(Map<String, dynamic> json) =>
    CampaignWeightOut(
      campaignId: json['campaign_id'] as String,
      campaignName: json['campaign_name'] as String,
      goalKg: json['goal_kg'] as num?,
      progressPct: json['progress_pct'] as num?,
      totalKg: json['total_kg'] as num,
    );

Map<String, dynamic> _$CampaignWeightOutToJson(CampaignWeightOut instance) =>
    <String, dynamic>{
      'campaign_id': instance.campaignId,
      'campaign_name': instance.campaignName,
      'goal_kg': instance.goalKg,
      'progress_pct': instance.progressPct,
      'total_kg': instance.totalKg,
    };
