// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportSummary _$ReportSummaryFromJson(Map<String, dynamic> json) =>
    ReportSummary(
      activeCenters: (json['active_centers'] as num).toInt(),
      draftBoxes: (json['draft_boxes'] as num).toInt(),
      rejectedBoxes: (json['rejected_boxes'] as num).toInt(),
      rejectionRate: json['rejection_rate'] as num,
      sealedBoxes: (json['sealed_boxes'] as num).toInt(),
      shippedBoxes: (json['shipped_boxes'] as num).toInt(),
      totalBoxes: (json['total_boxes'] as num).toInt(),
      totalIntakes: (json['total_intakes'] as num).toInt(),
      totalShipments: (json['total_shipments'] as num).toInt(),
      totalUnits: (json['total_units'] as num).toInt(),
    );

Map<String, dynamic> _$ReportSummaryToJson(ReportSummary instance) =>
    <String, dynamic>{
      'active_centers': instance.activeCenters,
      'draft_boxes': instance.draftBoxes,
      'rejected_boxes': instance.rejectedBoxes,
      'rejection_rate': instance.rejectionRate,
      'sealed_boxes': instance.sealedBoxes,
      'shipped_boxes': instance.shippedBoxes,
      'total_boxes': instance.totalBoxes,
      'total_intakes': instance.totalIntakes,
      'total_shipments': instance.totalShipments,
      'total_units': instance.totalUnits,
    };
