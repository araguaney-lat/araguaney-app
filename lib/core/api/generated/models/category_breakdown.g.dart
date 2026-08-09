// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryBreakdown _$CategoryBreakdownFromJson(Map<String, dynamic> json) =>
    CategoryBreakdown(
      boxCount: (json['box_count'] as num).toInt(),
      category: json['category'] as String,
      unitCount: (json['unit_count'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryBreakdownToJson(CategoryBreakdown instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'category': instance.category,
      'unit_count': instance.unitCount,
    };
