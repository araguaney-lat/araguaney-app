// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestOut _$RequestOutFromJson(Map<String, dynamic> json) => RequestOut(
  authorId: json['author_id'] as String?,
  centerId: json['center_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  description: json['description'] as String,
  id: json['id'] as String,
  status: json['status'] as String,
  title: json['title'] as String,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => RequestMessageOut.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$RequestOutToJson(RequestOut instance) =>
    <String, dynamic>{
      'author_id': instance.authorId,
      'center_id': instance.centerId,
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'id': instance.id,
      'messages': instance.messages,
      'status': instance.status,
      'title': instance.title,
      'updated_at': instance.updatedAt.toIso8601String(),
    };
