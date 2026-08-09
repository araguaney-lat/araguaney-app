// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_event_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferEventOut _$TransferEventOutFromJson(Map<String, dynamic> json) =>
    TransferEventOut(
      fromStatus: json['from_status'] as String?,
      id: json['id'] as String,
      note: json['note'] as String?,
      toStatus: json['to_status'] as String,
      transferId: json['transfer_id'] as String,
      ts: DateTime.parse(json['ts'] as String),
      userId: json['user_id'] as String?,
    );

Map<String, dynamic> _$TransferEventOutToJson(TransferEventOut instance) =>
    <String, dynamic>{
      'from_status': instance.fromStatus,
      'id': instance.id,
      'note': instance.note,
      'to_status': instance.toStatus,
      'transfer_id': instance.transferId,
      'ts': instance.ts.toIso8601String(),
      'user_id': instance.userId,
    };
