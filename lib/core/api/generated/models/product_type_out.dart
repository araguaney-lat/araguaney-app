// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_type_out.g.dart';

@JsonSerializable()
class ProductTypeOut {
  const ProductTypeOut({
    required this.brand,
    required this.campaignId,
    required this.category,
    required this.createdAt,
    required this.defaultUnit,
    required this.displayName,
    required this.form,
    required this.gtin,
    required this.id,
    required this.innName,
    required this.isControlled,
    required this.minShelfLifeDays,
    required this.strength,
    required this.unitWeightKg,
    required this.unspscCode,
  });

  factory ProductTypeOut.fromJson(Map<String, Object?> json) =>
      _$ProductTypeOutFromJson(json);

  final String? brand;
  @JsonKey(name: 'campaign_id')
  final String? campaignId;
  final String category;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'default_unit')
  final String? defaultUnit;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String? form;
  final String? gtin;
  final String id;
  @JsonKey(name: 'inn_name')
  final String? innName;
  @JsonKey(name: 'is_controlled')
  final bool isControlled;
  @JsonKey(name: 'min_shelf_life_days')
  final int? minShelfLifeDays;
  final String? strength;
  @JsonKey(name: 'unit_weight_kg')
  final String? unitWeightKg;
  @JsonKey(name: 'unspsc_code')
  final String? unspscCode;

  Map<String, Object?> toJson() => _$ProductTypeOutToJson(this);
}
