// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_event_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrEventOut _$QrEventOutFromJson(Map<String, dynamic> json) => QrEventOut(
  fromStatus: json['from_status'] as String?,
  note: json['note'] as String?,
  toStatus: json['to_status'] as String,
  ts: DateTime.parse(json['ts'] as String),
  milestone: json['milestone'] as String?,
);

Map<String, dynamic> _$QrEventOutToJson(QrEventOut instance) =>
    <String, dynamic>{
      'from_status': instance.fromStatus,
      'milestone': instance.milestone,
      'note': instance.note,
      'to_status': instance.toStatus,
      'ts': instance.ts.toIso8601String(),
    };
