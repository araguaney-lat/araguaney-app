// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceptionOut _$ReceptionOutFromJson(Map<String, dynamic> json) => ReceptionOut(
  consigneeName: json['consignee_name'] as String?,
  id: json['id'] as String,
  notes: json['notes'] as String?,
  receivedAt: DateTime.parse(json['received_at'] as String),
  shipmentId: json['shipment_id'] as String,
  shrinkage: ShrinkageOut.fromJson(json['shrinkage'] as Map<String, dynamic>),
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => ReceptionLineOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  palletWeights:
      (json['pallet_weights'] as List<dynamic>?)
          ?.map(
            (e) => ReceptionPalletWeightOut.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$ReceptionOutToJson(ReceptionOut instance) =>
    <String, dynamic>{
      'consignee_name': instance.consigneeName,
      'id': instance.id,
      'lines': instance.lines,
      'notes': instance.notes,
      'pallet_weights': instance.palletWeights,
      'received_at': instance.receivedAt.toIso8601String(),
      'shipment_id': instance.shipmentId,
      'shrinkage': instance.shrinkage,
    };
