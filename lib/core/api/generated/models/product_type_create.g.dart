// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_type_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductTypeCreate _$ProductTypeCreateFromJson(Map<String, dynamic> json) =>
    ProductTypeCreate(
      category: json['category'] as String,
      displayName: json['display_name'] as String,
      isControlled: json['is_controlled'] as bool? ?? false,
      brand: json['brand'] as String?,
      defaultUnit: json['default_unit'] as String?,
      form: json['form'] as String?,
      gtin: json['gtin'] as String?,
      innName: json['inn_name'] as String?,
      minShelfLifeDays: (json['min_shelf_life_days'] as num?)?.toInt(),
      strength: json['strength'] as String?,
      unitWeightKg: json['unit_weight_kg'],
      unspscCode: json['unspsc_code'] as String?,
    );

Map<String, dynamic> _$ProductTypeCreateToJson(ProductTypeCreate instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'category': instance.category,
      'default_unit': instance.defaultUnit,
      'display_name': instance.displayName,
      'form': instance.form,
      'gtin': instance.gtin,
      'inn_name': instance.innName,
      'is_controlled': instance.isControlled,
      'min_shelf_life_days': instance.minShelfLifeDays,
      'strength': instance.strength,
      'unit_weight_kg': instance.unitWeightKg,
      'unspsc_code': instance.unspscCode,
    };
