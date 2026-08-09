// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_upload_url_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoUploadUrlIn _$PhotoUploadUrlInFromJson(Map<String, dynamic> json) =>
    PhotoUploadUrlIn(
      contentType: json['content_type'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
    );

Map<String, dynamic> _$PhotoUploadUrlInToJson(PhotoUploadUrlIn instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
      'size_bytes': instance.sizeBytes,
    };
