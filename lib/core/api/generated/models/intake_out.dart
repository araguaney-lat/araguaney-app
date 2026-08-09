// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_schemas_intake_box_out.dart';
import 'donor_out.dart';

part 'intake_out.g.dart';

@JsonSerializable()
class IntakeOut {
  const IntakeOut({
    required this.campaignId,
    required this.centerId,
    required this.createdAt,
    required this.donanteLibre,
    required this.id,
    required this.notes,
    this.donor,
    this.boxes = const [],
  });

  factory IntakeOut.fromJson(Map<String, Object?> json) =>
      _$IntakeOutFromJson(json);

  final List<AppSchemasIntakeBoxOut> boxes;
  @JsonKey(name: 'campaign_id')
  final String campaignId;
  @JsonKey(name: 'center_id')
  final String centerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'donante_libre')
  final String? donanteLibre;
  final DonorOut? donor;
  final String id;
  final String? notes;

  Map<String, Object?> toJson() => _$IntakeOutToJson(this);
}
