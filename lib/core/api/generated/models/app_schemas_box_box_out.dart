// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_schemas_box_box_out.g.dart';

@JsonSerializable()
class AppSchemasBoxBoxOut {
  const AppSchemasBoxBoxOut({
    required this.batch,
    required this.centerId,
    required this.code,
    required this.createdAt,
    required this.expiryDate,
    required this.id,
    required this.intakeId,
    required this.palletId,
    required this.productTypeId,
    required this.quantity,
    required this.rejectReason,
    required this.sealedAt,
    required this.status,
    required this.unit,
    required this.weightKg,
  });

  factory AppSchemasBoxBoxOut.fromJson(Map<String, Object?> json) =>
      _$AppSchemasBoxBoxOutFromJson(json);

  final String? batch;
  @JsonKey(name: 'center_id')
  final String centerId;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  final String id;
  @JsonKey(name: 'intake_id')
  final String? intakeId;
  @JsonKey(name: 'pallet_id')
  final String? palletId;
  @JsonKey(name: 'product_type_id')
  final String productTypeId;
  final int quantity;
  @JsonKey(name: 'reject_reason')
  final String? rejectReason;
  @JsonKey(name: 'sealed_at')
  final DateTime? sealedAt;
  final String status;
  final String unit;
  @JsonKey(name: 'weight_kg')
  final String? weightKg;

  Map<String, Object?> toJson() => _$AppSchemasBoxBoxOutToJson(this);
}
