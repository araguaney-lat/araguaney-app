// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ai_daily_spend_out.g.dart';

@JsonSerializable()
class AiDailySpendOut {
  const AiDailySpendOut({
    required this.calls,
    required this.costUsd,
    required this.day,
  });

  factory AiDailySpendOut.fromJson(Map<String, Object?> json) =>
      _$AiDailySpendOutFromJson(json);

  final int calls;
  @JsonKey(name: 'cost_usd')
  final num costUsd;
  final DateTime day;

  Map<String, Object?> toJson() => _$AiDailySpendOutToJson(this);
}
