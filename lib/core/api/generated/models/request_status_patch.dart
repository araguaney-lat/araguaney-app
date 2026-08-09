// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'request_status_patch.g.dart';

@JsonSerializable()
class RequestStatusPatch {
  const RequestStatusPatch({required this.status});

  factory RequestStatusPatch.fromJson(Map<String, Object?> json) =>
      _$RequestStatusPatchFromJson(json);

  final String status;

  Map<String, Object?> toJson() => _$RequestStatusPatchToJson(this);
}
