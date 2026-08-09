// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pallet_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PalletOut _$PalletOutFromJson(Map<String, dynamic> json) => PalletOut(
  centerId: json['center_id'] as String,
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  code: json['code'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  id: json['id'] as String,
  notes: json['notes'] as String?,
  shipmentId: json['shipment_id'] as String?,
  status: json['status'] as String,
  tareWeightKg: json['tare_weight_kg'] as String?,
  grossWeightKg: json['gross_weight_kg'] as String?,
  heightCm: (json['height_cm'] as num?)?.toInt(),
);

Map<String, dynamic> _$PalletOutToJson(PalletOut instance) => <String, dynamic>{
  'center_id': instance.centerId,
  'closed_at': instance.closedAt?.toIso8601String(),
  'code': instance.code,
  'created_at': instance.createdAt.toIso8601String(),
  'gross_weight_kg': instance.grossWeightKg,
  'height_cm': instance.heightCm,
  'id': instance.id,
  'notes': instance.notes,
  'shipment_id': instance.shipmentId,
  'status': instance.status,
  'tare_weight_kg': instance.tareWeightKg,
};
