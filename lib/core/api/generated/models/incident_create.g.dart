// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncidentCreate _$IncidentCreateFromJson(Map<String, dynamic> json) =>
    IncidentCreate(
      description: json['description'] as String,
      type: json['type'] as String,
      boxId: json['box_id'] as String?,
      palletId: json['pallet_id'] as String?,
    );

Map<String, dynamic> _$IncidentCreateToJson(IncidentCreate instance) =>
    <String, dynamic>{
      'box_id': instance.boxId,
      'description': instance.description,
      'pallet_id': instance.palletId,
      'type': instance.type,
    };
