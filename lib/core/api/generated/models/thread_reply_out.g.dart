// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_reply_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadReplyOut _$ThreadReplyOutFromJson(Map<String, dynamic> json) =>
    ThreadReplyOut(
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      threadId: json['thread_id'] as String,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ThreadReplyOutToJson(ThreadReplyOut instance) =>
    <String, dynamic>{
      'attachments': instance.attachments,
      'body': instance.body,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'sender_id': instance.senderId,
      'thread_id': instance.threadId,
    };
