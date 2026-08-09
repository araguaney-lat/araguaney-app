// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'incident_resolve.g.dart';

@JsonSerializable()
class IncidentResolve {
  const IncidentResolve({required this.note});

  factory IncidentResolve.fromJson(Map<String, Object?> json) =>
      _$IncidentResolveFromJson(json);

  final String note;

  Map<String, Object?> toJson() => _$IncidentResolveToJson(this);
}
