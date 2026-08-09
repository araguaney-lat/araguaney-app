// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'risk_review_resolve_in.g.dart';

@JsonSerializable()
class RiskReviewResolveIn {
  const RiskReviewResolveIn({required this.resolution, this.note});

  factory RiskReviewResolveIn.fromJson(Map<String, Object?> json) =>
      _$RiskReviewResolveInFromJson(json);

  final String? note;
  final String resolution;

  Map<String, Object?> toJson() => _$RiskReviewResolveInToJson(this);
}
