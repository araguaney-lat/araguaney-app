// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountryPoint _$CountryPointFromJson(Map<String, dynamic> json) => CountryPoint(
  boxCount: (json['box_count'] as num).toInt(),
  centerCount: (json['center_count'] as num).toInt(),
  countryCode: json['country_code'] as String,
  unitCount: (json['unit_count'] as num).toInt(),
);

Map<String, dynamic> _$CountryPointToJson(CountryPoint instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'center_count': instance.centerCount,
      'country_code': instance.countryCode,
      'unit_count': instance.unitCount,
    };
