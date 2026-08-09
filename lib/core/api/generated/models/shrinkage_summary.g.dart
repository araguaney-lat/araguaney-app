// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shrinkage_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShrinkageSummary _$ShrinkageSummaryFromJson(Map<String, dynamic> json) =>
    ShrinkageSummary(
      damaged: (json['damaged'] as num).toInt(),
      missing: (json['missing'] as num).toInt(),
      received: (json['received'] as num).toInt(),
      reconciledBoxes: (json['reconciled_boxes'] as num).toInt(),
      retained: (json['retained'] as num).toInt(),
      shrinkagePct: json['shrinkage_pct'] as num,
    );

Map<String, dynamic> _$ShrinkageSummaryToJson(ShrinkageSummary instance) =>
    <String, dynamic>{
      'damaged': instance.damaged,
      'missing': instance.missing,
      'received': instance.received,
      'reconciled_boxes': instance.reconciledBoxes,
      'retained': instance.retained,
      'shrinkage_pct': instance.shrinkagePct,
    };
