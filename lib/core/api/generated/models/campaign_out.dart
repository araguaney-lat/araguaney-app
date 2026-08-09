// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_out.g.dart';

@JsonSerializable()
class CampaignOut {
  const CampaignOut({
    required this.createdAt,
    required this.description,
    required this.destinationCountry,
    required this.endDate,
    required this.id,
    required this.isActive,
    required this.isGeneral,
    required this.name,
    required this.originCountry,
    required this.slug,
    required this.startDate,
    required this.weightGoalKg,
  });

  factory CampaignOut.fromJson(Map<String, Object?> json) =>
      _$CampaignOutFromJson(json);

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String? description;
  @JsonKey(name: 'destination_country')
  final String? destinationCountry;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  final String id;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_general')
  final bool isGeneral;
  final String name;
  @JsonKey(name: 'origin_country')
  final String? originCountry;
  final String? slug;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  @JsonKey(name: 'weight_goal_kg')
  final String? weightGoalKg;

  Map<String, Object?> toJson() => _$CampaignOutToJson(this);
}
