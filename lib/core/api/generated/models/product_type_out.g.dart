// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_type_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductTypeOut _$ProductTypeOutFromJson(Map<String, dynamic> json) =>
    ProductTypeOut(
      brand: json['brand'] as String?,
      campaignId: json['campaign_id'] as String?,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      defaultUnit: json['default_unit'] as String?,
      displayName: json['display_name'] as String,
      form: json['form'] as String?,
      gtin: json['gtin'] as String?,
      id: json['id'] as String,
      innName: json['inn_name'] as String?,
      isControlled: json['is_controlled'] as bool,
      minShelfLifeDays: (json['min_shelf_life_days'] as num?)?.toInt(),
      strength: json['strength'] as String?,
      unitWeightKg: json['unit_weight_kg'] as String?,
      unspscCode: json['unspsc_code'] as String?,
    );

Map<String, dynamic> _$ProductTypeOutToJson(ProductTypeOut instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'campaign_id': instance.campaignId,
      'category': instance.category,
      'created_at': instance.createdAt.toIso8601String(),
      'default_unit': instance.defaultUnit,
      'display_name': instance.displayName,
      'form': instance.form,
      'gtin': instance.gtin,
      'id': instance.id,
      'inn_name': instance.innName,
      'is_controlled': instance.isControlled,
      'min_shelf_life_days': instance.minShelfLifeDays,
      'strength': instance.strength,
      'unit_weight_kg': instance.unitWeightKg,
      'unspsc_code': instance.unspscCode,
    };
