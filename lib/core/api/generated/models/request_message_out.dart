// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'request_message_out.g.dart';

@JsonSerializable()
class RequestMessageOut {
  const RequestMessageOut({
    required this.authorId,
    required this.body,
    required this.createdAt,
    required this.id,
    required this.requestId,
  });

  factory RequestMessageOut.fromJson(Map<String, Object?> json) =>
      _$RequestMessageOutFromJson(json);

  @JsonKey(name: 'author_id')
  final String? authorId;
  final String body;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'request_id')
  final String requestId;

  Map<String, Object?> toJson() => _$RequestMessageOutToJson(this);
}
