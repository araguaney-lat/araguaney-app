// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_review_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiskReviewOut _$RiskReviewOutFromJson(Map<String, dynamic> json) =>
    RiskReviewOut(
      boxes: json['boxes'] as String?,
      centerId: json['center_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      id: json['id'] as String,
      intakeId: json['intake_id'] as String?,
      kind: json['kind'] as String,
      reason: json['reason'] as String?,
      reviewNote: json['review_note'] as String?,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      status: json['status'] as String,
    );

Map<String, dynamic> _$RiskReviewOutToJson(RiskReviewOut instance) =>
    <String, dynamic>{
      'boxes': instance.boxes,
      'center_id': instance.centerId,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'intake_id': instance.intakeId,
      'kind': instance.kind,
      'reason': instance.reason,
      'review_note': instance.reviewNote,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'status': instance.status,
    };
