// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'category_stock_out.g.dart';

@JsonSerializable()
class CategoryStockOut {
  const CategoryStockOut({
    required this.boxCount,
    required this.category,
    required this.totalUnits,
  });

  factory CategoryStockOut.fromJson(Map<String, Object?> json) =>
      _$CategoryStockOutFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  final String category;
  @JsonKey(name: 'total_units')
  final int totalUnits;

  Map<String, Object?> toJson() => _$CategoryStockOutToJson(this);
}
