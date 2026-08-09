// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'request_message_out.dart';

part 'request_out.g.dart';

@JsonSerializable()
class RequestOut {
  const RequestOut({
    required this.authorId,
    required this.centerId,
    required this.createdAt,
    required this.description,
    required this.id,
    required this.status,
    required this.title,
    required this.updatedAt,
    this.messages = const [],
  });

  factory RequestOut.fromJson(Map<String, Object?> json) =>
      _$RequestOutFromJson(json);

  @JsonKey(name: 'author_id')
  final String? authorId;
  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String description;
  final String id;
  final List<RequestMessageOut> messages;
  final String status;
  final String title;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$RequestOutToJson(this);
}
