// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MilestoneIn _$MilestoneInFromJson(Map<String, dynamic> json) => MilestoneIn(
  milestone: json['milestone'] as String,
  note: json['note'] as String?,
  occurredAt: json['occurred_at'] == null
      ? null
      : DateTime.parse(json['occurred_at'] as String),
);

Map<String, dynamic> _$MilestoneInToJson(MilestoneIn instance) =>
    <String, dynamic>{
      'milestone': instance.milestone,
      'note': instance.note,
      'occurred_at': instance.occurredAt?.toIso8601String(),
    };
