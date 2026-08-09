// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_create.g.dart';

@JsonSerializable()
class CampaignCreate {
  const CampaignCreate({
    required this.name,
    this.centerIds,
    this.description,
    this.destinationCountry,
    this.endDate,
    this.originCountry,
    this.startDate,
  });

  factory CampaignCreate.fromJson(Map<String, Object?> json) =>
      _$CampaignCreateFromJson(json);

  @JsonKey(name: 'center_ids')
  final List<String>? centerIds;
  final String? description;
  @JsonKey(name: 'destination_country')
  final String? destinationCountry;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  final String name;
  @JsonKey(name: 'origin_country')
  final String? originCountry;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;

  Map<String, Object?> toJson() => _$CampaignCreateToJson(this);
}
