// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shrinkage_summary.g.dart';

/// Merma de la campaña. `reconciled_boxes` es la base: sin envíos recibidos.
/// no hay merma que reportar, y cero cajas no es lo mismo que cero merma.
@JsonSerializable()
class ShrinkageSummary {
  const ShrinkageSummary({
    required this.damaged,
    required this.missing,
    required this.received,
    required this.reconciledBoxes,
    required this.retained,
    required this.shrinkagePct,
  });

  factory ShrinkageSummary.fromJson(Map<String, Object?> json) =>
      _$ShrinkageSummaryFromJson(json);

  final int damaged;
  final int missing;
  final int received;
  @JsonKey(name: 'reconciled_boxes')
  final int reconciledBoxes;
  final int retained;
  @JsonKey(name: 'shrinkage_pct')
  final num shrinkagePct;

  Map<String, Object?> toJson() => _$ShrinkageSummaryToJson(this);
}
