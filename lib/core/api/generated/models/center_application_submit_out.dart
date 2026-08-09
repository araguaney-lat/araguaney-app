// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_application_submit_out.g.dart';

/// Response to a public submit — no internal fields leaked.
@JsonSerializable()
class CenterApplicationSubmitOut {
  const CenterApplicationSubmitOut({required this.id, required this.status});

  factory CenterApplicationSubmitOut.fromJson(Map<String, Object?> json) =>
      _$CenterApplicationSubmitOutFromJson(json);

  final String id;
  final String status;

  Map<String, Object?> toJson() => _$CenterApplicationSubmitOutToJson(this);
}
