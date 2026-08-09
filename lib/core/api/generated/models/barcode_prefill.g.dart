// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_prefill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BarcodePrefill _$BarcodePrefillFromJson(Map<String, dynamic> json) =>
    BarcodePrefill(
      brand: json['brand'] as String?,
      category: json['category'] as String,
      displayName: json['display_name'] as String,
      gtin: json['gtin'] as String,
    );

Map<String, dynamic> _$BarcodePrefillToJson(BarcodePrefill instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'category': instance.category,
      'display_name': instance.displayName,
      'gtin': instance.gtin,
    };
