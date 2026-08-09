// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_application_reject.g.dart';

@JsonSerializable()
class CenterApplicationReject {
  const CenterApplicationReject({required this.reason});

  factory CenterApplicationReject.fromJson(Map<String, Object?> json) =>
      _$CenterApplicationRejectFromJson(json);

  final String reason;

  Map<String, Object?> toJson() => _$CenterApplicationRejectToJson(this);
}
