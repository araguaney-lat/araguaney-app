// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'barcode_prefill.g.dart';

@JsonSerializable()
class BarcodePrefill {
  const BarcodePrefill({
    required this.brand,
    required this.category,
    required this.displayName,
    required this.gtin,
  });

  factory BarcodePrefill.fromJson(Map<String, Object?> json) =>
      _$BarcodePrefillFromJson(json);

  final String? brand;
  final String category;
  @JsonKey(name: 'display_name')
  final String displayName;
  final String gtin;

  Map<String, Object?> toJson() => _$BarcodePrefillToJson(this);
}
