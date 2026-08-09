// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentOut _$AttachmentOutFromJson(Map<String, dynamic> json) =>
    AttachmentOut(
      contentType: json['content_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      filename: json['filename'] as String,
      id: json['id'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
    );

Map<String, dynamic> _$AttachmentOutToJson(AttachmentOut instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
      'created_at': instance.createdAt.toIso8601String(),
      'filename': instance.filename,
      'id': instance.id,
      'size_bytes': instance.sizeBytes,
    };
