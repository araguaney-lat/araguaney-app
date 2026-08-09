// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_intake_box_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSchemasIntakeBoxOut _$AppSchemasIntakeBoxOutFromJson(
  Map<String, dynamic> json,
) => AppSchemasIntakeBoxOut(
  batch: json['batch'] as String?,
  code: json['code'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.parse(json['expiry_date'] as String),
  id: json['id'] as String,
  productTypeId: json['product_type_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  rejectReason: json['reject_reason'] as String?,
  status: json['status'] as String,
  unit: json['unit'] as String,
  weightKg: json['weight_kg'] as String?,
);

Map<String, dynamic> _$AppSchemasIntakeBoxOutToJson(
  AppSchemasIntakeBoxOut instance,
) => <String, dynamic>{
  'batch': instance.batch,
  'code': instance.code,
  'created_at': instance.createdAt.toIso8601String(),
  'expiry_date': instance.expiryDate?.toIso8601String(),
  'id': instance.id,
  'product_type_id': instance.productTypeId,
  'quantity': instance.quantity,
  'reject_reason': instance.rejectReason,
  'status': instance.status,
  'unit': instance.unit,
  'weight_kg': instance.weightKg,
};
