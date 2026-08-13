// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'qr_event_out.dart';
import 'qr_pallet_box_row.dart';

part 'qr_pallet_ficha.g.dart';

@JsonSerializable()
class QrPalletFicha {
  const QrPalletFicha({
    required this.boxCount,
    required this.boxes,
    required this.centerName,
    required this.closedAt,
    required this.code,
    required this.createdAt,
    required this.events,
    required this.status,
    required this.totalWeightKg,
    this.deliveredAt,
    this.delivered = false,
    this.kind = 'pallet',
  });

  factory QrPalletFicha.fromJson(Map<String, Object?> json) =>
      _$QrPalletFichaFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  final List<QrPalletBoxRow> boxes;
  @JsonKey(name: 'center_name')
  final String centerName;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final bool delivered;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  final List<QrEventOut> events;
  final String kind;
  final String status;
  @JsonKey(name: 'total_weight_kg')
  final String? totalWeightKg;

  Map<String, Object?> toJson() => _$QrPalletFichaToJson(this);
}
