// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_box_ficha.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrBoxFicha _$QrBoxFichaFromJson(Map<String, dynamic> json) => QrBoxFicha(
  batch: json['batch'] as String?,
  campaignName: json['campaign_name'] as String?,
  category: json['category'] as String,
  centerName: json['center_name'] as String,
  code: json['code'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  displayName: json['display_name'] as String,
  events: (json['events'] as List<dynamic>)
      .map((e) => QrEventOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  expiryDate: json['expiry_date'] == null
      ? null
      : DateTime.parse(json['expiry_date'] as String),
  form: json['form'] as String?,
  innName: json['inn_name'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  sealedAt: json['sealed_at'] == null
      ? null
      : DateTime.parse(json['sealed_at'] as String),
  status: json['status'] as String,
  strength: json['strength'] as String?,
  unit: json['unit'] as String,
  weightKg: json['weight_kg'] as String?,
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  delivered: json['delivered'] as bool? ?? false,
  kind: json['kind'] as String? ?? 'box',
);

Map<String, dynamic> _$QrBoxFichaToJson(QrBoxFicha instance) =>
    <String, dynamic>{
      'batch': instance.batch,
      'campaign_name': instance.campaignName,
      'category': instance.category,
      'center_name': instance.centerName,
      'code': instance.code,
      'created_at': instance.createdAt.toIso8601String(),
      'delivered': instance.delivered,
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'display_name': instance.displayName,
      'events': instance.events,
      'expiry_date': instance.expiryDate?.toIso8601String(),
      'form': instance.form,
      'inn_name': instance.innName,
      'kind': instance.kind,
      'quantity': instance.quantity,
      'sealed_at': instance.sealedAt?.toIso8601String(),
      'status': instance.status,
      'strength': instance.strength,
      'unit': instance.unit,
      'weight_kg': instance.weightKg,
    };
