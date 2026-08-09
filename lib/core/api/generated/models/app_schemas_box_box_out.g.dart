// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_schemas_box_box_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSchemasBoxBoxOut _$AppSchemasBoxBoxOutFromJson(Map<String, dynamic> json) =>
    AppSchemasBoxBoxOut(
      batch: json['batch'] as String?,
      centerId: json['center_id'] as String,
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiryDate: json['expiry_date'] == null
          ? null
          : DateTime.parse(json['expiry_date'] as String),
      id: json['id'] as String,
      intakeId: json['intake_id'] as String?,
      palletId: json['pallet_id'] as String?,
      productTypeId: json['product_type_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      rejectReason: json['reject_reason'] as String?,
      sealedAt: json['sealed_at'] == null
          ? null
          : DateTime.parse(json['sealed_at'] as String),
      status: json['status'] as String,
      unit: json['unit'] as String,
      weightKg: json['weight_kg'] as String?,
    );

Map<String, dynamic> _$AppSchemasBoxBoxOutToJson(
  AppSchemasBoxBoxOut instance,
) => <String, dynamic>{
  'batch': instance.batch,
  'center_id': instance.centerId,
  'code': instance.code,
  'created_at': instance.createdAt.toIso8601String(),
  'expiry_date': instance.expiryDate?.toIso8601String(),
  'id': instance.id,
  'intake_id': instance.intakeId,
  'pallet_id': instance.palletId,
  'product_type_id': instance.productTypeId,
  'quantity': instance.quantity,
  'reject_reason': instance.rejectReason,
  'sealed_at': instance.sealedAt?.toIso8601String(),
  'status': instance.status,
  'unit': instance.unit,
  'weight_kg': instance.weightKg,
};
