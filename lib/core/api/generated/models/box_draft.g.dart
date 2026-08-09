// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoxDraft _$BoxDraftFromJson(Map<String, dynamic> json) => BoxDraft(
  productTypeId: json['product_type_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unit: json['unit'] as String,
  batch: json['batch'] as String?,
  code: json['code'] as String?,
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.parse(json['expiry_date'] as String),
  gtin: json['gtin'] as String?,
  weightKg: json['weight_kg'],
);

Map<String, dynamic> _$BoxDraftToJson(BoxDraft instance) => <String, dynamic>{
  'batch': instance.batch,
  'code': instance.code,
  'expiry_date': instance.expiryDate?.toIso8601String(),
  'gtin': instance.gtin,
  'product_type_id': instance.productTypeId,
  'quantity': instance.quantity,
  'unit': instance.unit,
  'weight_kg': instance.weightKg,
};
