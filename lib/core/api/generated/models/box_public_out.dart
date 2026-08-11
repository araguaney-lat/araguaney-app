// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'box_public_out.g.dart';

/// Public-facing box ficha — no PII, safe to cache at the edge.
@JsonSerializable()
class BoxPublicOut {
  const BoxPublicOut({
    required this.category,
    required this.code,
    required this.displayName,
    required this.expiryDate,
    required this.quantity,
    required this.sealedAt,
    required this.status,
    required this.unit,
    this.deliveredAt,
    this.delivered = false,
  });

  factory BoxPublicOut.fromJson(Map<String, Object?> json) =>
      _$BoxPublicOutFromJson(json);

  final String category;
  final String code;
  final bool delivered;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  final int quantity;
  @JsonKey(name: 'sealed_at')
  final DateTime? sealedAt;
  final String status;
  final String unit;

  Map<String, Object?> toJson() => _$BoxPublicOutToJson(this);
}
