// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_stock_out.g.dart';

@JsonSerializable()
class CenterStockOut {
  const CenterStockOut({
    required this.boxCount,
    required this.centerId,
    required this.centerName,
    required this.countryCode,
    required this.stateName,
    required this.totalUnits,
  });

  factory CenterStockOut.fromJson(Map<String, Object?> json) =>
      _$CenterStockOutFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  @JsonKey(name: 'center_id')
  final String centerId;
  @JsonKey(name: 'center_name')
  final String centerName;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'state_name')
  final String? stateName;
  @JsonKey(name: 'total_units')
  final int totalUnits;

  Map<String, Object?> toJson() => _$CenterStockOutToJson(this);
}
