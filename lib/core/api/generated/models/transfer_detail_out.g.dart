// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_detail_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDetailOut _$TransferDetailOutFromJson(Map<String, dynamic> json) =>
    TransferDetailOut(
      boxes: (json['boxes'] as List<dynamic>)
          .map((e) => AppSchemasBoxBoxOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      events: (json['events'] as List<dynamic>)
          .map((e) => TransferEventOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      fromCenterId: json['from_center_id'] as String,
      id: json['id'] as String,
      initiatedBy: json['initiated_by'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      toCenterId: json['to_center_id'] as String,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TransferDetailOutToJson(TransferDetailOut instance) =>
    <String, dynamic>{
      'boxes': instance.boxes,
      'created_at': instance.createdAt.toIso8601String(),
      'events': instance.events,
      'from_center_id': instance.fromCenterId,
      'id': instance.id,
      'initiated_by': instance.initiatedBy,
      'notes': instance.notes,
      'status': instance.status,
      'to_center_id': instance.toCenterId,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
