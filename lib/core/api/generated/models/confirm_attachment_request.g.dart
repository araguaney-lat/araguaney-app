// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_attachment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmAttachmentRequest _$ConfirmAttachmentRequestFromJson(
  Map<String, dynamic> json,
) => ConfirmAttachmentRequest(
  contentType: json['content_type'] as String,
  filename: json['filename'] as String,
  r2Key: json['r2_key'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  replyId: json['reply_id'] as String?,
  threadId: json['thread_id'] as String?,
);

Map<String, dynamic> _$ConfirmAttachmentRequestToJson(
  ConfirmAttachmentRequest instance,
) => <String, dynamic>{
  'content_type': instance.contentType,
  'filename': instance.filename,
  'r2_key': instance.r2Key,
  'reply_id': instance.replyId,
  'size_bytes': instance.sizeBytes,
  'thread_id': instance.threadId,
};
