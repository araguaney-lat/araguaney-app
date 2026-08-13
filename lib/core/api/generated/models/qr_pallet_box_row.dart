// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'qr_pallet_box_row.g.dart';

@JsonSerializable()
class QrPalletBoxRow {
  const QrPalletBoxRow({
    required this.category,
    required this.displayName,
    required this.quantity,
    required this.unit,
    required this.weightKg,
  });

  factory QrPalletBoxRow.fromJson(Map<String, Object?> json) =>
      _$QrPalletBoxRowFromJson(json);

  final String category;
  @JsonKey(name: 'display_name')
  final String displayName;
  final int quantity;
  final String unit;
  @JsonKey(name: 'weight_kg')
  final String? weightKg;

  Map<String, Object?> toJson() => _$QrPalletBoxRowToJson(this);
}
