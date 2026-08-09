// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_capability_usage_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiCapabilityUsageOut _$AiCapabilityUsageOutFromJson(
  Map<String, dynamic> json,
) => AiCapabilityUsageOut(
  calls: (json['calls'] as num).toInt(),
  capability: json['capability'] as String,
  costUsd: json['cost_usd'] as num,
  enabled: json['enabled'] as bool,
  inputTokens: (json['input_tokens'] as num).toInt(),
  outputTokens: (json['output_tokens'] as num).toInt(),
);

Map<String, dynamic> _$AiCapabilityUsageOutToJson(
  AiCapabilityUsageOut instance,
) => <String, dynamic>{
  'calls': instance.calls,
  'capability': instance.capability,
  'cost_usd': instance.costUsd,
  'enabled': instance.enabled,
  'input_tokens': instance.inputTokens,
  'output_tokens': instance.outputTokens,
};
