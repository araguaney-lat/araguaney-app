// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'attachment_out.dart';

part 'thread_reply_out.g.dart';

@JsonSerializable()
class ThreadReplyOut {
  const ThreadReplyOut({
    required this.body,
    required this.createdAt,
    required this.id,
    required this.senderId,
    required this.threadId,
    this.attachments = const [],
  });

  factory ThreadReplyOut.fromJson(Map<String, Object?> json) =>
      _$ThreadReplyOutFromJson(json);

  final List<AttachmentOut> attachments;
  final String body;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'sender_id')
  final String? senderId;
  @JsonKey(name: 'thread_id')
  final String threadId;

  Map<String, Object?> toJson() => _$ThreadReplyOutToJson(this);
}
