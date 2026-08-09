// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_update.g.dart';

@JsonSerializable()
class CampaignUpdate {
  const CampaignUpdate({
    this.description,
    this.destinationCountry,
    this.endDate,
    this.isActive,
    this.name,
    this.originCountry,
    this.startDate,
    this.weightGoalKg,
  });

  factory CampaignUpdate.fromJson(Map<String, Object?> json) =>
      _$CampaignUpdateFromJson(json);

  final String? description;
  @JsonKey(name: 'destination_country')
  final String? destinationCountry;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  final String? name;
  @JsonKey(name: 'origin_country')
  final String? originCountry;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'weight_goal_kg')
  final dynamic weightGoalKg;

  Map<String, Object?> toJson() => _$CampaignUpdateToJson(this);
}
