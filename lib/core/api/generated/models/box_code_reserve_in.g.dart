// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_code_reserve_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoxCodeReserveIn _$BoxCodeReserveInFromJson(Map<String, dynamic> json) =>
    BoxCodeReserveIn(
      count: (json['count'] as num).toInt(),
      centerId: json['center_id'] as String?,
    );

Map<String, dynamic> _$BoxCodeReserveInToJson(BoxCodeReserveIn instance) =>
    <String, dynamic>{'center_id': instance.centerId, 'count': instance.count};
