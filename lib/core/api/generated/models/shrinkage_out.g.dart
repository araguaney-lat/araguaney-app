// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shrinkage_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShrinkageOut _$ShrinkageOutFromJson(Map<String, dynamic> json) => ShrinkageOut(
  notReceived: (json['not_received'] as num).toInt(),
  received: (json['received'] as num).toInt(),
  shrinkagePct: json['shrinkage_pct'] as num,
  totalBoxes: (json['total_boxes'] as num).toInt(),
);

Map<String, dynamic> _$ShrinkageOutToJson(ShrinkageOut instance) =>
    <String, dynamic>{
      'not_received': instance.notReceived,
      'received': instance.received,
      'shrinkage_pct': instance.shrinkagePct,
      'total_boxes': instance.totalBoxes,
    };
