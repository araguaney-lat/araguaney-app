// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_review_resolve_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RiskReviewResolveIn _$RiskReviewResolveInFromJson(Map<String, dynamic> json) =>
    RiskReviewResolveIn(
      resolution: json['resolution'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$RiskReviewResolveInToJson(
  RiskReviewResolveIn instance,
) => <String, dynamic>{
  'note': instance.note,
  'resolution': instance.resolution,
};
