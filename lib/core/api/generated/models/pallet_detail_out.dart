// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_schemas_box_box_out.dart';

part 'pallet_detail_out.g.dart';

@JsonSerializable()
class PalletDetailOut {
  const PalletDetailOut({
    required this.boxes,
    required this.centerId,
    required this.closedAt,
    required this.code,
    required this.createdAt,
    required this.id,
    required this.notes,
    required this.shipmentId,
    required this.status,
    this.boxesWeightKg,
    this.grossWeightKg,
    this.heightCm,
    this.tareWeightKg,
    this.weightDiscrepancyKg,
  });

  factory PalletDetailOut.fromJson(Map<String, Object?> json) =>
      _$PalletDetailOutFromJson(json);

  final List<AppSchemasBoxBoxOut> boxes;
  @JsonKey(name: 'boxes_weight_kg')
  final String? boxesWeightKg;
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
  @JsonKey(name: 'weight_discrepancy_kg')
  final String? weightDiscrepancyKg;

  Map<String, Object?> toJson() => _$PalletDetailOutToJson(this);
}
