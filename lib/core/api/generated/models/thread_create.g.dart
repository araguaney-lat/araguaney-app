// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThreadCreate _$ThreadCreateFromJson(Map<String, dynamic> json) => ThreadCreate(
  body: json['body'] as String,
  campaignId: json['campaign_id'] as String,
  threadType: json['thread_type'] as String,
  title: json['title'] as String,
  recipientIds:
      (json['recipient_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$ThreadCreateToJson(ThreadCreate instance) =>
    <String, dynamic>{
      'body': instance.body,
      'campaign_id': instance.campaignId,
      'recipient_ids': instance.recipientIds,
      'thread_type': instance.threadType,
      'title': instance.title,
    };
