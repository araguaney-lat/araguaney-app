// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'upload_url_request.g.dart';

@JsonSerializable()
class UploadUrlRequest {
  const UploadUrlRequest({
    required this.contentType,
    required this.filename,
    required this.sizeBytes,
  });

  factory UploadUrlRequest.fromJson(Map<String, Object?> json) =>
      _$UploadUrlRequestFromJson(json);

  @JsonKey(name: 'content_type')
  final String contentType;
  final String filename;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  Map<String, Object?> toJson() => _$UploadUrlRequestToJson(this);
}
