// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_breakdown.g.dart';

@JsonSerializable()
class CenterBreakdown {
  const CenterBreakdown({
    required this.boxCount,
    required this.centerId,
    required this.centerName,
    required this.countryCode,
    required this.unitCount,
  });

  factory CenterBreakdown.fromJson(Map<String, Object?> json) =>
      _$CenterBreakdownFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  @JsonKey(name: 'center_id')
  final String centerId;
  @JsonKey(name: 'center_name')
  final String centerName;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'unit_count')
  final int unitCount;

  Map<String, Object?> toJson() => _$CenterBreakdownToJson(this);
}
