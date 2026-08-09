// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_totals_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SummaryTotalsOut _$SummaryTotalsOutFromJson(Map<String, dynamic> json) =>
    SummaryTotalsOut(
      activeCenters: (json['active_centers'] as num).toInt(),
      totalBoxesSealed: (json['total_boxes_sealed'] as num).toInt(),
      totalIntakes: (json['total_intakes'] as num).toInt(),
      totalShipmentsSent: (json['total_shipments_sent'] as num).toInt(),
      totalUnitsSealed: (json['total_units_sealed'] as num).toInt(),
      totalWeightKg: json['total_weight_kg'] as num,
    );

Map<String, dynamic> _$SummaryTotalsOutToJson(SummaryTotalsOut instance) =>
    <String, dynamic>{
      'active_centers': instance.activeCenters,
      'total_boxes_sealed': instance.totalBoxesSealed,
      'total_intakes': instance.totalIntakes,
      'total_shipments_sent': instance.totalShipmentsSent,
      'total_units_sealed': instance.totalUnitsSealed,
      'total_weight_kg': instance.totalWeightKg,
    };
