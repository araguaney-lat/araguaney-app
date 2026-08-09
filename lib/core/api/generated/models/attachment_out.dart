// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'attachment_out.g.dart';

@JsonSerializable()
class AttachmentOut {
  const AttachmentOut({
    required this.contentType,
    required this.createdAt,
    required this.filename,
    required this.id,
    required this.sizeBytes,
  });

  factory AttachmentOut.fromJson(Map<String, Object?> json) =>
      _$AttachmentOutFromJson(json);

  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String filename;
  final String id;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  Map<String, Object?> toJson() => _$AttachmentOutToJson(this);
}
