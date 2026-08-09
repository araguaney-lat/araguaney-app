// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_gtin_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductGtinOut _$ProductGtinOutFromJson(Map<String, dynamic> json) =>
    ProductGtinOut(
      createdAt: DateTime.parse(json['created_at'] as String),
      gtin: json['gtin'] as String,
      id: json['id'] as String,
      source: json['source'] as String,
    );

Map<String, dynamic> _$ProductGtinOutToJson(ProductGtinOut instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt.toIso8601String(),
      'gtin': instance.gtin,
      'id': instance.id,
      'source': instance.source,
    };
