// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_confirm_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoConfirmIn _$PhotoConfirmInFromJson(Map<String, dynamic> json) =>
    PhotoConfirmIn(
      contentType: json['content_type'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      storageKey: json['storage_key'] as String,
    );

Map<String, dynamic> _$PhotoConfirmInToJson(PhotoConfirmIn instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
      'size_bytes': instance.sizeBytes,
      'storage_key': instance.storageKey,
    };
