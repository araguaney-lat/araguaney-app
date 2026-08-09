// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_weight_out.g.dart';

@JsonSerializable()
class CampaignWeightOut {
  const CampaignWeightOut({
    required this.campaignId,
    required this.campaignName,
    required this.goalKg,
    required this.progressPct,
    required this.totalKg,
  });

  factory CampaignWeightOut.fromJson(Map<String, Object?> json) =>
      _$CampaignWeightOutFromJson(json);

  @JsonKey(name: 'campaign_id')
  final String campaignId;
  @JsonKey(name: 'campaign_name')
  final String campaignName;
  @JsonKey(name: 'goal_kg')
  final num? goalKg;
  @JsonKey(name: 'progress_pct')
  final num? progressPct;
  @JsonKey(name: 'total_kg')
  final num totalKg;

  Map<String, Object?> toJson() => _$CampaignWeightOutToJson(this);
}
