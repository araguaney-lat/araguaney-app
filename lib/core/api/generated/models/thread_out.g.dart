// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadOut _$ThreadOutFromJson(Map<String, dynamic> json) => ThreadOut(
  body: json['body'] as String,
  campaignId: json['campaign_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  id: json['id'] as String,
  senderId: json['sender_id'] as String?,
  threadType: json['thread_type'] as String,
  title: json['title'] as String,
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ThreadOutToJson(ThreadOut instance) => <String, dynamic>{
  'body': instance.body,
  'campaign_id': instance.campaignId,
  'created_at': instance.createdAt.toIso8601String(),
  'id': instance.id,
  'sender_id': instance.senderId,
  'thread_type': instance.threadType,
  'title': instance.title,
  'updated_at': instance.updatedAt.toIso8601String(),
};
