// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ai_center_spend_out.g.dart';

@JsonSerializable()
class AiCenterSpendOut {
  const AiCenterSpendOut({required this.centerName, required this.costUsd});

  factory AiCenterSpendOut.fromJson(Map<String, Object?> json) =>
      _$AiCenterSpendOutFromJson(json);

  @JsonKey(name: 'center_name')
  final String centerName;
  @JsonKey(name: 'cost_usd')
  final num costUsd;

  Map<String, Object?> toJson() => _$AiCenterSpendOutToJson(this);
}
