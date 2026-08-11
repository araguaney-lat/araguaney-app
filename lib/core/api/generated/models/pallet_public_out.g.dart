// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pallet_public_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PalletPublicOut _$PalletPublicOutFromJson(Map<String, dynamic> json) =>
    PalletPublicOut(
      boxCount: (json['box_count'] as num).toInt(),
      centerName: json['center_name'] as String,
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      code: json['code'] as String,
      status: json['status'] as String,
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      delivered: json['delivered'] as bool? ?? false,
    );

Map<String, dynamic> _$PalletPublicOutToJson(PalletPublicOut instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'center_name': instance.centerName,
      'closed_at': instance.closedAt?.toIso8601String(),
      'code': instance.code,
      'delivered': instance.delivered,
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'status': instance.status,
    };
