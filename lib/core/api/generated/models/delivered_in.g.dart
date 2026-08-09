// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivered_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveredIn _$DeliveredInFromJson(Map<String, dynamic> json) => DeliveredIn(
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$DeliveredInToJson(DeliveredIn instance) =>
    <String, dynamic>{
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'note': instance.note,
    };
