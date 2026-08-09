// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ai_capability_usage_out.g.dart';

@JsonSerializable()
class AiCapabilityUsageOut {
  const AiCapabilityUsageOut({
    required this.calls,
    required this.capability,
    required this.costUsd,
    required this.enabled,
    required this.inputTokens,
    required this.outputTokens,
  });

  factory AiCapabilityUsageOut.fromJson(Map<String, Object?> json) =>
      _$AiCapabilityUsageOutFromJson(json);

  final int calls;
  final String capability;
  @JsonKey(name: 'cost_usd')
  final num costUsd;
  final bool enabled;
  @JsonKey(name: 'input_tokens')
  final int inputTokens;
  @JsonKey(name: 'output_tokens')
  final int outputTokens;

  Map<String, Object?> toJson() => _$AiCapabilityUsageOutToJson(this);
}
