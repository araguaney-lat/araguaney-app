// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_stock_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterStockOut _$CenterStockOutFromJson(Map<String, dynamic> json) =>
    CenterStockOut(
      boxCount: (json['box_count'] as num).toInt(),
      centerId: json['center_id'] as String,
      centerName: json['center_name'] as String,
      countryCode: json['country_code'] as String?,
      stateName: json['state_name'] as String?,
      totalUnits: (json['total_units'] as num).toInt(),
    );

Map<String, dynamic> _$CenterStockOutToJson(CenterStockOut instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'center_id': instance.centerId,
      'center_name': instance.centerName,
      'country_code': instance.countryCode,
      'state_name': instance.stateName,
      'total_units': instance.totalUnits,
    };
