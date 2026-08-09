// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_line_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceptionLineOut _$ReceptionLineOutFromJson(Map<String, dynamic> json) =>
    ReceptionLineOut(
      boxId: json['box_id'] as String,
      note: json['note'] as String?,
      outcome: json['outcome'] as String,
    );

Map<String, dynamic> _$ReceptionLineOutToJson(ReceptionLineOut instance) =>
    <String, dynamic>{
      'box_id': instance.boxId,
      'note': instance.note,
      'outcome': instance.outcome,
    };
