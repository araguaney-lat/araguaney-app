// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'photo_upload_url_out.g.dart';

@JsonSerializable()
class PhotoUploadUrlOut {
  const PhotoUploadUrlOut({required this.storageKey, required this.uploadUrl});

  factory PhotoUploadUrlOut.fromJson(Map<String, Object?> json) =>
      _$PhotoUploadUrlOutFromJson(json);

  @JsonKey(name: 'storage_key')
  final String storageKey;
  @JsonKey(name: 'upload_url')
  final String uploadUrl;

  Map<String, Object?> toJson() => _$PhotoUploadUrlOutToJson(this);
}
