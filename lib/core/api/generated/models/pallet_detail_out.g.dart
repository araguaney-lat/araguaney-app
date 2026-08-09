// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pallet_detail_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PalletDetailOut _$PalletDetailOutFromJson(Map<String, dynamic> json) =>
    PalletDetailOut(
      boxes: (json['boxes'] as List<dynamic>)
          .map((e) => AppSchemasBoxBoxOut.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      boxesWeightKg: json['boxes_weight_kg'] as String?,
      grossWeightKg: json['gross_weight_kg'] as String?,
      heightCm: (json['height_cm'] as num?)?.toInt(),
      tareWeightKg: json['tare_weight_kg'] as String?,
      weightDiscrepancyKg: json['weight_discrepancy_kg'] as String?,
    );

Map<String, dynamic> _$PalletDetailOutToJson(PalletDetailOut instance) =>
    <String, dynamic>{
      'boxes': instance.boxes,
      'boxes_weight_kg': instance.boxesWeightKg,
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
      'weight_discrepancy_kg': instance.weightDiscrepancyKg,
    };
