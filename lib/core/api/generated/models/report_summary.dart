// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'report_summary.g.dart';

@JsonSerializable()
class ReportSummary {
  const ReportSummary({
    required this.activeCenters,
    required this.draftBoxes,
    required this.rejectedBoxes,
    required this.rejectionRate,
    required this.sealedBoxes,
    required this.shippedBoxes,
    required this.totalBoxes,
    required this.totalIntakes,
    required this.totalShipments,
    required this.totalUnits,
  });

  factory ReportSummary.fromJson(Map<String, Object?> json) =>
      _$ReportSummaryFromJson(json);

  @JsonKey(name: 'active_centers')
  final int activeCenters;
  @JsonKey(name: 'draft_boxes')
  final int draftBoxes;
  @JsonKey(name: 'rejected_boxes')
  final int rejectedBoxes;
  @JsonKey(name: 'rejection_rate')
  final num rejectionRate;
  @JsonKey(name: 'sealed_boxes')
  final int sealedBoxes;
  @JsonKey(name: 'shipped_boxes')
  final int shippedBoxes;
  @JsonKey(name: 'total_boxes')
  final int totalBoxes;
  @JsonKey(name: 'total_intakes')
  final int totalIntakes;
  @JsonKey(name: 'total_shipments')
  final int totalShipments;
  @JsonKey(name: 'total_units')
  final int totalUnits;

  Map<String, Object?> toJson() => _$ReportSummaryToJson(this);
}
