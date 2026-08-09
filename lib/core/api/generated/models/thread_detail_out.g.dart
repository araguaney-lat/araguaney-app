// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_detail_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadDetailOut _$ThreadDetailOutFromJson(Map<String, dynamic> json) =>
    ThreadDetailOut(
      body: json['body'] as String,
      campaignId: json['campaign_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      threadType: json['thread_type'] as String,
      title: json['title'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      participantIds:
          (json['participant_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      replies:
          (json['replies'] as List<dynamic>?)
              ?.map((e) => ThreadReplyOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ThreadDetailOutToJson(ThreadDetailOut instance) =>
    <String, dynamic>{
      'attachments': instance.attachments,
      'body': instance.body,
      'campaign_id': instance.campaignId,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'participant_ids': instance.participantIds,
      'replies': instance.replies,
      'sender_id': instance.senderId,
      'thread_type': instance.threadType,
      'title': instance.title,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
