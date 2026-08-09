// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_url_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadUrlRequest _$UploadUrlRequestFromJson(Map<String, dynamic> json) =>
    UploadUrlRequest(
      contentType: json['content_type'] as String,
      filename: json['filename'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
    );

Map<String, dynamic> _$UploadUrlRequestToJson(UploadUrlRequest instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
      'filename': instance.filename,
      'size_bytes': instance.sizeBytes,
    };
