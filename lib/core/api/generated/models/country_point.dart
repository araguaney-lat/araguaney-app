// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'country_point.g.dart';

@JsonSerializable()
class CountryPoint {
  const CountryPoint({
    required this.boxCount,
    required this.centerCount,
    required this.countryCode,
    required this.unitCount,
  });

  factory CountryPoint.fromJson(Map<String, Object?> json) =>
      _$CountryPointFromJson(json);

  @JsonKey(name: 'box_count')
  final int boxCount;
  @JsonKey(name: 'center_count')
  final int centerCount;
  @JsonKey(name: 'country_code')
  final String countryCode;
  @JsonKey(name: 'unit_count')
  final int unitCount;

  Map<String, Object?> toJson() => _$CountryPointToJson(this);
}
