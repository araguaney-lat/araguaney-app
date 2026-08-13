// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_pallet_ficha.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrPalletFicha _$QrPalletFichaFromJson(Map<String, dynamic> json) =>
    QrPalletFicha(
      boxCount: (json['box_count'] as num).toInt(),
      boxes: (json['boxes'] as List<dynamic>)
          .map((e) => QrPalletBoxRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      centerName: json['center_name'] as String,
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
      code: json['code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      events: (json['events'] as List<dynamic>)
          .map((e) => QrEventOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      totalWeightKg: json['total_weight_kg'] as String?,
      deliveredAt: json['delivered_at'] == null
          ? null
          : DateTime.parse(json['delivered_at'] as String),
      delivered: json['delivered'] as bool? ?? false,
      kind: json['kind'] as String? ?? 'pallet',
    );

Map<String, dynamic> _$QrPalletFichaToJson(QrPalletFicha instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'boxes': instance.boxes,
      'center_name': instance.centerName,
      'closed_at': instance.closedAt?.toIso8601String(),
      'code': instance.code,
      'created_at': instance.createdAt.toIso8601String(),
      'delivered': instance.delivered,
      'delivered_at': instance.deliveredAt?.toIso8601String(),
      'events': instance.events,
      'kind': instance.kind,
      'status': instance.status,
      'total_weight_kg': instance.totalWeightKg,
    };
