// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'summary_totals_out.g.dart';

@JsonSerializable()
class SummaryTotalsOut {
  const SummaryTotalsOut({
    required this.activeCenters,
    required this.totalBoxesSealed,
    required this.totalIntakes,
    required this.totalShipmentsSent,
    required this.totalUnitsSealed,
    required this.totalWeightKg,
  });

  factory SummaryTotalsOut.fromJson(Map<String, Object?> json) =>
      _$SummaryTotalsOutFromJson(json);

  @JsonKey(name: 'active_centers')
  final int activeCenters;
  @JsonKey(name: 'total_boxes_sealed')
  final int totalBoxesSealed;
  @JsonKey(name: 'total_intakes')
  final int totalIntakes;
  @JsonKey(name: 'total_shipments_sent')
  final int totalShipmentsSent;
  @JsonKey(name: 'total_units_sealed')
  final int totalUnitsSealed;
  @JsonKey(name: 'total_weight_kg')
  final num totalWeightKg;

  Map<String, Object?> toJson() => _$SummaryTotalsOutToJson(this);
}
