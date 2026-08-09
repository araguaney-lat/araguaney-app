// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_center_spend_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AiCenterSpendOut _$AiCenterSpendOutFromJson(Map<String, dynamic> json) =>
    AiCenterSpendOut(
      centerName: json['center_name'] as String,
      costUsd: json['cost_usd'] as num,
    );

Map<String, dynamic> _$AiCenterSpendOutToJson(AiCenterSpendOut instance) =>
    <String, dynamic>{
      'center_name': instance.centerName,
      'cost_usd': instance.costUsd,
    };
