// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_usage_report_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiUsageReportOut _$AiUsageReportOutFromJson(Map<String, dynamic> json) =>
    AiUsageReportOut(
      budgetExhausted: json['budget_exhausted'] as bool,
      capabilities: (json['capabilities'] as List<dynamic>)
          .map((e) => AiCapabilityUsageOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List<dynamic>)
          .map((e) => AiDailySpendOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      model: json['model'] as String,
      monthSpendUsd: json['month_spend_usd'] as num,
      monthStart: DateTime.parse(json['month_start'] as String),
      monthlyBudgetUsd: json['monthly_budget_usd'] as num,
      providerConfigured: json['provider_configured'] as bool,
      topCenters: (json['top_centers'] as List<dynamic>)
          .map((e) => AiCenterSpendOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AiUsageReportOutToJson(AiUsageReportOut instance) =>
    <String, dynamic>{
      'budget_exhausted': instance.budgetExhausted,
      'capabilities': instance.capabilities,
      'daily': instance.daily,
      'model': instance.model,
      'month_spend_usd': instance.monthSpendUsd,
      'month_start': instance.monthStart.toIso8601String(),
      'monthly_budget_usd': instance.monthlyBudgetUsd,
      'provider_configured': instance.providerConfigured,
      'top_centers': instance.topCenters,
    };
