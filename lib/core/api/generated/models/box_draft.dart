// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'box_draft.g.dart';

@JsonSerializable()
class BoxDraft {
  const BoxDraft({
    required this.productTypeId,
    required this.quantity,
    required this.unit,
    this.batch,
    this.code,
    this.expiryDate,
    this.gtin,
    this.weightKg,
  });

  factory BoxDraft.fromJson(Map<String, Object?> json) =>
      _$BoxDraftFromJson(json);

  final String? batch;
  final String? code;
  @JsonKey(name: 'expiry_date')
  final DateTime? expiryDate;
  final String? gtin;
  @JsonKey(name: 'product_type_id')
  final String productTypeId;
  final int quantity;
  final String unit;
  @JsonKey(name: 'weight_kg')
  final dynamic weightKg;

  Map<String, Object?> toJson() => _$BoxDraftToJson(this);
}
