// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'category_breakdown.g.dart';

@JsonSerializable()
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.boxCount,
    required this.category,
    required this.unitCount,
  });

  factory CategoryBreakdown.fromJson(Map<String, Object?> json) =>
      _$CategoryBreakdownFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  final String category;
  @JsonKey(name: 'unit_count')
  final int unitCount;

  Map<String, Object?> toJson() => _$CategoryBreakdownToJson(this);
}
