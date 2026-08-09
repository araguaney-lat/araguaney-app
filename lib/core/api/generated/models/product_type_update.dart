// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_type_update.g.dart';

@JsonSerializable()
class ProductTypeUpdate {
  const ProductTypeUpdate({
    this.brand,
    this.category,
    this.defaultUnit,
    this.displayName,
    this.form,
    this.gtin,
    this.innName,
    this.isControlled,
    this.minShelfLifeDays,
    this.strength,
    this.unitWeightKg,
    this.unspscCode,
  });

  factory ProductTypeUpdate.fromJson(Map<String, Object?> json) =>
      _$ProductTypeUpdateFromJson(json);

  final String? brand;
  final String? category;
  @JsonKey(name: 'default_unit')
  final String? defaultUnit;
  @JsonKey(name: 'display_name')
  final String? displayName;
  final String? form;
  final String? gtin;
  @JsonKey(name: 'inn_name')
  final String? innName;
  @JsonKey(name: 'is_controlled')
  final bool? isControlled;
  @JsonKey(name: 'min_shelf_life_days')
  final int? minShelfLifeDays;
  final String? strength;
  @JsonKey(name: 'unit_weight_kg')
  final dynamic unitWeightKg;
  @JsonKey(name: 'unspsc_code')
  final String? unspscCode;

  Map<String, Object?> toJson() => _$ProductTypeUpdateToJson(this);
}
