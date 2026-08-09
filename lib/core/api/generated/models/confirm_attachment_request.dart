// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'confirm_attachment_request.g.dart';

@JsonSerializable()
class ConfirmAttachmentRequest {
  const ConfirmAttachmentRequest({
    required this.contentType,
    required this.filename,
    required this.r2Key,
    required this.sizeBytes,
    this.replyId,
    this.threadId,
  });

  factory ConfirmAttachmentRequest.fromJson(Map<String, Object?> json) =>
      _$ConfirmAttachmentRequestFromJson(json);

  @JsonKey(name: 'content_type')
  final String contentType;
  final String filename;
  @JsonKey(name: 'r2_key')
  final String r2Key;
  @JsonKey(name: 'reply_id')
  final String? replyId;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;
  @JsonKey(name: 'thread_id')
  final String? threadId;

  Map<String, Object?> toJson() => _$ConfirmAttachmentRequestToJson(this);
}
