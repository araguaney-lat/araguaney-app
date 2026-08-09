// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_stock_out.dart';

part 'public_needs_out.g.dart';

@JsonSerializable()
class PublicNeedsOut {
  const PublicNeedsOut({required this.byCategory});

  factory PublicNeedsOut.fromJson(Map<String, Object?> json) =>
      _$PublicNeedsOutFromJson(json);

  @JsonKey(name: 'by_category')
  final List<CategoryStockOut> byCategory;

  Map<String, Object?> toJson() => _$PublicNeedsOutToJson(this);
}
