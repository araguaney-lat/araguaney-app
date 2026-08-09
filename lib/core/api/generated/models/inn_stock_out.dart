// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'inn_stock_out.g.dart';

@JsonSerializable()
class InnStockOut {
  const InnStockOut({
    required this.boxCount,
    required this.form,
    required this.innName,
    required this.strength,
    required this.totalUnits,
  });

  factory InnStockOut.fromJson(Map<String, Object?> json) =>
      _$InnStockOutFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  final String? form;
  @JsonKey(name: 'inn_name')
  final String? innName;
  final String? strength;
  @JsonKey(name: 'total_units')
  final int totalUnits;

  Map<String, Object?> toJson() => _$InnStockOutToJson(this);
}
