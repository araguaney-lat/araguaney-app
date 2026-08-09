// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_message_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestMessageOut _$RequestMessageOutFromJson(Map<String, dynamic> json) =>
    RequestMessageOut(
      authorId: json['author_id'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      id: json['id'] as String,
      requestId: json['request_id'] as String,
    );

Map<String, dynamic> _$RequestMessageOutToJson(RequestMessageOut instance) =>
    <String, dynamic>{
      'author_id': instance.authorId,
      'body': instance.body,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'request_id': instance.requestId,
    };
