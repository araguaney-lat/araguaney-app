// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'barcode_prefill.dart';
import 'barcode_result_source.dart';
import 'product_type_out.dart';

part 'barcode_result.g.dart';

@JsonSerializable()
class BarcodeResult {
  const BarcodeResult({required this.source, this.prefill, this.productType});

  factory BarcodeResult.fromJson(Map<String, Object?> json) =>
      _$BarcodeResultFromJson(json);

  final BarcodePrefill? prefill;
  @JsonKey(name: 'product_type')
  final ProductTypeOut? productType;
  final BarcodeResultSource source;

  Map<String, Object?> toJson() => _$BarcodeResultToJson(this);
}
