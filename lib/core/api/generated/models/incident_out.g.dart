// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncidentOut _$IncidentOutFromJson(Map<String, dynamic> json) => IncidentOut(
  boxId: json['box_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  description: json['description'] as String,
  id: json['id'] as String,
  palletId: json['pallet_id'] as String?,
  resolutionNote: json['resolution_note'] as String?,
  resolvedAt: json['resolved_at'] == null
      ? null
      : DateTime.parse(json['resolved_at'] as String),
  shipmentId: json['shipment_id'] as String,
  status: json['status'] as String,
  type: json['type'] as String,
);

Map<String, dynamic> _$IncidentOutToJson(IncidentOut instance) =>
    <String, dynamic>{
      'box_id': instance.boxId,
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'id': instance.id,
      'pallet_id': instance.palletId,
      'resolution_note': instance.resolutionNote,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'shipment_id': instance.shipmentId,
      'status': instance.status,
      'type': instance.type,
    };
