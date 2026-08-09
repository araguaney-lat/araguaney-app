// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'ai_capability_usage_out.dart';
import 'ai_center_spend_out.dart';
import 'ai_daily_spend_out.dart';

part 'ai_usage_report_out.g.dart';

@JsonSerializable()
class AiUsageReportOut {
  const AiUsageReportOut({
    required this.budgetExhausted,
    required this.capabilities,
    required this.daily,
    required this.model,
    required this.monthSpendUsd,
    required this.monthStart,
    required this.monthlyBudgetUsd,
    required this.providerConfigured,
    required this.topCenters,
  });

  factory AiUsageReportOut.fromJson(Map<String, Object?> json) =>
      _$AiUsageReportOutFromJson(json);

  @JsonKey(name: 'budget_exhausted')
  final bool budgetExhausted;
  final List<AiCapabilityUsageOut> capabilities;
  final List<AiDailySpendOut> daily;
  final String model;
  @JsonKey(name: 'month_spend_usd')
  final num monthSpendUsd;
  @JsonKey(name: 'month_start')
  final DateTime monthStart;
  @JsonKey(name: 'monthly_budget_usd')
  final num monthlyBudgetUsd;
  @JsonKey(name: 'provider_configured')
  final bool providerConfigured;
  @JsonKey(name: 'top_centers')
  final List<AiCenterSpendOut> topCenters;

  Map<String, Object?> toJson() => _$AiUsageReportOutToJson(this);
}
