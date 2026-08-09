// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'campaign_weight_out.dart';

part 'weight_dashboard_out.g.dart';

@JsonSerializable()
class WeightDashboardOut {
  const WeightDashboardOut({required this.campaigns, required this.centerKg});

  factory WeightDashboardOut.fromJson(Map<String, Object?> json) =>
      _$WeightDashboardOutFromJson(json);

  final List<CampaignWeightOut> campaigns;
  @JsonKey(name: 'center_kg')
  final num? centerKg;

  Map<String, Object?> toJson() => _$WeightDashboardOutToJson(this);
}
