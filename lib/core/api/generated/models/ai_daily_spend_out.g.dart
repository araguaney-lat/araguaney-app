// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_daily_spend_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiDailySpendOut _$AiDailySpendOutFromJson(Map<String, dynamic> json) =>
    AiDailySpendOut(
      calls: (json['calls'] as num).toInt(),
      costUsd: json['cost_usd'] as num,
      day: DateTime.parse(json['day'] as String),
    );

Map<String, dynamic> _$AiDailySpendOutToJson(AiDailySpendOut instance) =>
    <String, dynamic>{
      'calls': instance.calls,
      'cost_usd': instance.costUsd,
      'day': instance.day.toIso8601String(),
    };
