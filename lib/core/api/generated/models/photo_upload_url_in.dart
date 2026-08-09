// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'photo_upload_url_in.g.dart';

@JsonSerializable()
class PhotoUploadUrlIn {
  const PhotoUploadUrlIn({required this.contentType, required this.sizeBytes});

  factory PhotoUploadUrlIn.fromJson(Map<String, Object?> json) =>
      _$PhotoUploadUrlInFromJson(json);

  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  Map<String, Object?> toJson() => _$PhotoUploadUrlInToJson(this);
}
