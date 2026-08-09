// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'risk_review_out.g.dart';

@JsonSerializable()
class RiskReviewOut {
  const RiskReviewOut({
    required this.boxes,
    required this.centerId,
    required this.createdAt,
    required this.id,
    required this.intakeId,
    required this.kind,
    required this.reason,
    required this.reviewNote,
    required this.reviewedAt,
    required this.status,
  });

  factory RiskReviewOut.fromJson(Map<String, Object?> json) =>
      _$RiskReviewOutFromJson(json);

  final String? boxes;
  @JsonKey(name: 'center_id')
  final String centerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'intake_id')
  final String? intakeId;
  final String kind;
  final String? reason;
  @JsonKey(name: 'review_note')
  final String? reviewNote;
  @JsonKey(name: 'reviewed_at')
  final DateTime? reviewedAt;
  final String status;

  Map<String, Object?> toJson() => _$RiskReviewOutToJson(this);
}
