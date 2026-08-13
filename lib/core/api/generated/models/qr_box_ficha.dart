// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'qr_event_out.dart';

part 'qr_box_ficha.g.dart';

@JsonSerializable()
class QrBoxFicha {
  const QrBoxFicha({
    required this.batch,
    required this.campaignName,
    required this.category,
    required this.centerName,
    required this.code,
    required this.createdAt,
    required this.displayName,
    required this.events,
    required this.expiryDate,
    required this.form,
    required this.innName,
    required this.quantity,
    required this.sealedAt,
    required this.status,
    required this.strength,
    required this.unit,
    required this.weightKg,
    this.deliveredAt,
    this.delivered = false,
    this.kind = 'box',
  });

  factory QrBoxFicha.fromJson(Map<String, Object?> json) =>
      _$QrBoxFichaFromJson(json);

  final String? batch;
  @JsonKey(name: 'campaign_name')
  final String? campaignName;
  final String category;
  @JsonKey(name: 'center_name')
  final String centerName;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final bool delivered;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  @JsonKey(name: 'display_name')
  final String displayName;
  final List<QrEventOut> events;
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  final String? form;
  @JsonKey(name: 'inn_name')
  final String? innName;
  final String kind;
  final int quantity;
  @JsonKey(name: 'sealed_at')
  final DateTime? sealedAt;
  final String status;
  final String? strength;
  final String unit;
  @JsonKey(name: 'weight_kg')
  final String? weightKg;

  Map<String, Object?> toJson() => _$QrBoxFichaToJson(this);
}
