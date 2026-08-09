// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reception_line_out.g.dart';

@JsonSerializable()
class ReceptionLineOut {
  const ReceptionLineOut({
    required this.boxId,
    required this.note,
    required this.outcome,
  });

  factory ReceptionLineOut.fromJson(Map<String, Object?> json) =>
      _$ReceptionLineOutFromJson(json);

  @JsonKey(name: 'box_id')
  final String boxId;
  final String? note;
  final String outcome;

  Map<String, Object?> toJson() => _$ReceptionLineOutToJson(this);
}
