// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'product_gtin_out.g.dart';

@JsonSerializable()
class ProductGtinOut {
  const ProductGtinOut({
    required this.createdAt,
    required this.gtin,
    required this.id,
    required this.source,
  });

  factory ProductGtinOut.fromJson(Map<String, Object?> json) =>
      _$ProductGtinOutFromJson(json);

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String gtin;
  final String id;
  final String source;

  Map<String, Object?> toJson() => _$ProductGtinOutToJson(this);
}
