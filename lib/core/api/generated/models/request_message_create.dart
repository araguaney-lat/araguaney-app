// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'request_message_create.g.dart';

@JsonSerializable()
class RequestMessageCreate {
  const RequestMessageCreate({required this.body});

  factory RequestMessageCreate.fromJson(Map<String, Object?> json) =>
      _$RequestMessageCreateFromJson(json);

  final String body;

  Map<String, Object?> toJson() => _$RequestMessageCreateToJson(this);
}
