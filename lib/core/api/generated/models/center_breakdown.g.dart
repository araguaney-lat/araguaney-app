// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterBreakdown _$CenterBreakdownFromJson(Map<String, dynamic> json) =>
    CenterBreakdown(
      boxCount: (json['box_count'] as num).toInt(),
      centerId: json['center_id'] as String,
      centerName: json['center_name'] as String,
      countryCode: json['country_code'] as String?,
      unitCount: (json['unit_count'] as num).toInt(),
    );

Map<String, dynamic> _$CenterBreakdownToJson(CenterBreakdown instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'center_id': instance.centerId,
      'center_name': instance.centerName,
      'country_code': instance.countryCode,
      'unit_count': instance.unitCount,
    };
