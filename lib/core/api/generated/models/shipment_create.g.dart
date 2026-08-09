// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentCreate _$ShipmentCreateFromJson(Map<String, dynamic> json) =>
    ShipmentCreate(
      destination: json['destination'] as String? ?? 'Venezuela',
      campaignId: json['campaign_id'] as String?,
      carrier: json['carrier'] as String?,
      centerId: json['center_id'] as String?,
      heightProfile: json['height_profile'] as String?,
      notes: json['notes'] as String?,
      reference: json['reference'] as String?,
    );

Map<String, dynamic> _$ShipmentCreateToJson(ShipmentCreate instance) =>
    <String, dynamic>{
      'campaign_id': instance.campaignId,
      'carrier': instance.carrier,
      'center_id': instance.centerId,
      'destination': instance.destination,
      'height_profile': instance.heightProfile,
      'notes': instance.notes,
      'reference': instance.reference,
    };
