// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferOut _$TransferOutFromJson(Map<String, dynamic> json) => TransferOut(
  createdAt: DateTime.parse(json['created_at'] as String),
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

Map<String, dynamic> _$TransferOutToJson(TransferOut instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt.toIso8601String(),
      'from_center_id': instance.fromCenterId,
      'id': instance.id,
      'initiated_by': instance.initiatedBy,
      'notes': instance.notes,
      'status': instance.status,
      'to_center_id': instance.toCenterId,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
