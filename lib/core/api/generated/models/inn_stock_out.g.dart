// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inn_stock_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InnStockOut _$InnStockOutFromJson(Map<String, dynamic> json) => InnStockOut(
  boxCount: (json['box_count'] as num).toInt(),
  form: json['form'] as String?,
  innName: json['inn_name'] as String?,
  strength: json['strength'] as String?,
  totalUnits: (json['total_units'] as num).toInt(),
);

Map<String, dynamic> _$InnStockOutToJson(InnStockOut instance) =>
    <String, dynamic>{
      'box_count': instance.boxCount,
      'form': instance.form,
      'inn_name': instance.innName,
      'strength': instance.strength,
      'total_units': instance.totalUnits,
    };
