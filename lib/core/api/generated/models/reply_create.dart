// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reply_create.g.dart';

@JsonSerializable()
class ReplyCreate {
  const ReplyCreate({required this.body});

  factory ReplyCreate.fromJson(Map<String, Object?> json) =>
      _$ReplyCreateFromJson(json);

  final String body;

  Map<String, Object?> toJson() => _$ReplyCreateToJson(this);
}
