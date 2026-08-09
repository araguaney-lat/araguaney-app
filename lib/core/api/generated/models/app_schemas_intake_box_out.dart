// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_schemas_intake_box_out.g.dart';

@JsonSerializable()
class AppSchemasIntakeBoxOut {
  const AppSchemasIntakeBoxOut({
    required this.batch,
    required this.code,
    required this.createdAt,
    required this.expiryDate,
    required this.id,
    required this.productTypeId,
    required this.quantity,
    required this.rejectReason,
    required this.status,
    required this.unit,
    required this.weightKg,
  });

  factory AppSchemasIntakeBoxOut.fromJson(Map<String, Object?> json) =>
      _$AppSchemasIntakeBoxOutFromJson(json);

  final String? batch;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  final String id;
  @JsonKey(name: 'product_type_id')
  final String productTypeId;
  final int quantity;
  @JsonKey(name: 'reject_reason')
  final String? rejectReason;
  final String status;
  final String unit;
  @JsonKey(name: 'weight_kg')
  final String? weightKg;

  Map<String, Object?> toJson() => _$AppSchemasIntakeBoxOutToJson(this);
}
