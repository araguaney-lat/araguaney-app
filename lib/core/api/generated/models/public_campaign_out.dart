// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_stock_out.dart';

part 'public_campaign_out.g.dart';

/// Public event-landing payload — campaign context + what's needed for it.
@JsonSerializable()
class PublicCampaignOut {
  const PublicCampaignOut({
    required this.byCategory,
    required this.description,
    required this.destinationCountry,
    required this.endDate,
    required this.name,
    required this.slug,
    required this.startDate,
  });

  factory PublicCampaignOut.fromJson(Map<String, Object?> json) =>
      _$PublicCampaignOutFromJson(json);

  @JsonKey(name: 'by_category')
  final List<CategoryStockOut> byCategory;
  final String? description;
  @JsonKey(name: 'destination_country')
  final String? destinationCountry;
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  final String name;
  final String slug;
  @JsonKey(name: 'start_date')
  final DateTime? startDate;

  Map<String, Object?> toJson() => _$PublicCampaignOutToJson(this);
}
