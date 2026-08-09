// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentOut _$ShipmentOutFromJson(Map<String, dynamic> json) => ShipmentOut(
  campaignId: json['campaign_id'] as String?,
  carrier: json['carrier'] as String?,
  centerId: json['center_id'] as String?,
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  destination: json['destination'] as String,
  id: json['id'] as String,
  notes: json['notes'] as String?,
  reference: json['reference'] as String?,
  shippedAt: json['shipped_at'] == null
      ? null
      : DateTime.parse(json['shipped_at'] as String),
  status: json['status'] as String,
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  heightProfile: json['height_profile'] as String?,
  reconciledAt: json['reconciled_at'] == null
      ? null
      : DateTime.parse(json['reconciled_at'] as String),
);

Map<String, dynamic> _$ShipmentOutToJson(ShipmentOut instance) =>
    <String, dynamic>{
      'campaign_id': instance.campaignId,
      'carrier': instance.carrier,
      'center_id': instance.centerId,
      'closed_at': instance.closedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'destination': instance.destination,
      'height_profile': instance.heightProfile,
      'id': instance.id,
      'notes': instance.notes,
      'reconciled_at': instance.reconciledAt?.toIso8601String(),
      'reference': instance.reference,
      'shipped_at': instance.shippedAt?.toIso8601String(),
      'status': instance.status,
    };
