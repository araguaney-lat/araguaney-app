// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shrinkage_out.g.dart';

@JsonSerializable()
class ShrinkageOut {
  const ShrinkageOut({
    required this.notReceived,
    required this.received,
    required this.shrinkagePct,
    required this.totalBoxes,
  });

  factory ShrinkageOut.fromJson(Map<String, Object?> json) =>
      _$ShrinkageOutFromJson(json);

  @JsonKey(name: 'not_received')
  final int notReceived;
  final int received;
  @JsonKey(name: 'shrinkage_pct')
  final num shrinkagePct;
  @JsonKey(name: 'total_boxes')
  final int totalBoxes;

  Map<String, Object?> toJson() => _$ShrinkageOutToJson(this);
}
