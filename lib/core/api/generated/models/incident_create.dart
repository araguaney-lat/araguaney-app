// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'incident_create.g.dart';

@JsonSerializable()
class IncidentCreate {
  const IncidentCreate({
    required this.description,
    required this.type,
    this.boxId,
    this.palletId,
  });

  factory IncidentCreate.fromJson(Map<String, Object?> json) =>
      _$IncidentCreateFromJson(json);

  @JsonKey(name: 'box_id')
  final String? boxId;
  final String description;
  @JsonKey(name: 'pallet_id')
  final String? palletId;
  final String type;

  Map<String, Object?> toJson() => _$IncidentCreateToJson(this);
}
