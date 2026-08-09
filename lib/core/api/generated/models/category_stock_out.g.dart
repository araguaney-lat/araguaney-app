// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_stock_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryStockOut _$CategoryStockOutFromJson(Map<String, dynamic> json) =>
    CategoryStockOut(
      boxCount: (json['box_count'] as num).toInt(),
      category: json['category'] as String,
      totalUnits: (json['total_units'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryStockOutToJson(CategoryStockOut instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'category': instance.category,
      'total_units': instance.totalUnits,
    };
