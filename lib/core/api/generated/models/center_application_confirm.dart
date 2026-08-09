// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_application_confirm.g.dart';

@JsonSerializable()
class CenterApplicationConfirm {
  const CenterApplicationConfirm({required this.token});

  factory CenterApplicationConfirm.fromJson(Map<String, Object?> json) =>
      _$CenterApplicationConfirmFromJson(json);

  final String token;

  Map<String, Object?> toJson() => _$CenterApplicationConfirmToJson(this);
}
