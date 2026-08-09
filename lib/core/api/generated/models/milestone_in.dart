// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'milestone_in.g.dart';

/// Hito logístico. `occurred_at` es opcional porque el reporte del.
/// consignatario suele llegar tarde y describir algo de ayer.
@JsonSerializable()
class MilestoneIn {
  const MilestoneIn({required this.milestone, this.note, this.occurredAt});

  factory MilestoneIn.fromJson(Map<String, Object?> json) =>
      _$MilestoneInFromJson(json);

  final String milestone;
  final String? note;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;

  Map<String, Object?> toJson() => _$MilestoneInToJson(this);
}
