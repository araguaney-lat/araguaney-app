// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pallet_out.g.dart';

@JsonSerializable()
class PalletOut {
  const PalletOut({
    required this.centerId,
    required this.closedAt,
    required this.code,
    required this.createdAt,
    required this.id,
    required this.notes,
    required this.shipmentId,
    required this.status,
    required this.tareWeightKg,
    this.grossWeightKg,
    this.heightCm,
  });

  factory PalletOut.fromJson(Map<String, Object?> json) =>
      _$PalletOutFromJson(json);

  @JsonKey(name: 'center_id')
  final String centerId;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'gross_weight_kg')
  final String? grossWeightKg;
  @JsonKey(name: 'height_cm')
  final int? heightCm;
  final String id;
  final String? notes;
  @JsonKey(name: 'shipment_id')
  final String? shipmentId;
  final String status;
  @JsonKey(name: 'tare_weight_kg')
  final String? tareWeightKg;

  Map<String, Object?> toJson() => _$PalletOutToJson(this);
}
