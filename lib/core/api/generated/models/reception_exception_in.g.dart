// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_exception_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceptionExceptionIn _$ReceptionExceptionInFromJson(
  Map<String, dynamic> json,
) => ReceptionExceptionIn(
  boxId: json['box_id'] as String,
  outcome: json['outcome'] as String,
  note: json['note'] as String?,
);

Map<String, dynamic> _$ReceptionExceptionInToJson(
  ReceptionExceptionIn instance,
) => <String, dynamic>{
  'box_id': instance.boxId,
  'note': instance.note,
  'outcome': instance.outcome,
};
