// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'qr_event_out.g.dart';

@JsonSerializable()
class QrEventOut {
  const QrEventOut({
    required this.fromStatus,
    required this.note,
    required this.toStatus,
    required this.ts,
    this.milestone,
  });

  factory QrEventOut.fromJson(Map<String, Object?> json) =>
      _$QrEventOutFromJson(json);

  @JsonKey(name: 'from_status')
  final String? fromStatus;
  final String? milestone;
  final String? note;
  @JsonKey(name: 'to_status')
  final String toStatus;
  final DateTime ts;

  Map<String, Object?> toJson() => _$QrEventOutToJson(this);
}
