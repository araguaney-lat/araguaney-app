// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_public_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoxPublicOut _$BoxPublicOutFromJson(Map<String, dynamic> json) => BoxPublicOut(
  category: json['category'] as String,
  code: json['code'] as String,
  displayName: json['display_name'] as String,
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.parse(json['expiry_date'] as String),
  quantity: (json['quantity'] as num).toInt(),
  sealedAt: json['sealed_at'] == null
      ? null
      : DateTime.parse(json['sealed_at'] as String),
  status: json['status'] as String,
  unit: json['unit'] as String,
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  delivered: json['delivered'] as bool? ?? false,
);

Map<String, dynamic> _$BoxPublicOutToJson(BoxPublicOut instance) =>
    <String, dynamic>{
      'category': instance.category,
      'code': instance.code,
      'delivered': instance.delivered,
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'display_name': instance.displayName,
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'quantity': instance.quantity,
      'sealed_at': instance.sealedAt?.toIso8601String(),
      'status': instance.status,
      'unit': instance.unit,
    };
