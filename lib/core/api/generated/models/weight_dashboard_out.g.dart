// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_dashboard_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeightDashboardOut _$WeightDashboardOutFromJson(Map<String, dynamic> json) =>
    WeightDashboardOut(
      campaigns: (json['campaigns'] as List<dynamic>)
          .map((e) => CampaignWeightOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      centerKg: json['center_kg'] as num?,
    );

Map<String, dynamic> _$WeightDashboardOutToJson(WeightDashboardOut instance) =>
    <String, dynamic>{
      'campaigns': instance.campaigns,
      'center_kg': instance.centerKg,
    };
