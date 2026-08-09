// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_summary.g.dart';

@JsonSerializable()
class CampaignSummary {
  const CampaignSummary({required this.id, required this.name});

  factory CampaignSummary.fromJson(Map<String, Object?> json) =>
      _$CampaignSummaryFromJson(json);

  final String id;
  final String name;

  Map<String, Object?> toJson() => _$CampaignSummaryToJson(this);
}
