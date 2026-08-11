// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pallet_public_out.g.dart';

/// Public pallet ficha — no PII, safe to cache at the edge.
@JsonSerializable()
class PalletPublicOut {
  const PalletPublicOut({
    required this.boxCount,
    required this.centerName,
    required this.closedAt,
    required this.code,
    required this.status,
    this.deliveredAt,
    this.delivered = false,
  });

  factory PalletPublicOut.fromJson(Map<String, Object?> json) =>
      _$PalletPublicOutFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  @JsonKey(name: 'center_name')
  final String centerName;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  final String code;
  final bool delivered;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  final String status;

  Map<String, Object?> toJson() => _$PalletPublicOutToJson(this);
}
