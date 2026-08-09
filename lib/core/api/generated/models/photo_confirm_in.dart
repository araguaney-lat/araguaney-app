// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'photo_confirm_in.g.dart';

@JsonSerializable()
class PhotoConfirmIn {
  const PhotoConfirmIn({
    required this.contentType,
    required this.sizeBytes,
    required this.storageKey,
  });

  factory PhotoConfirmIn.fromJson(Map<String, Object?> json) =>
      _$PhotoConfirmInFromJson(json);

  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;
  @JsonKey(name: 'storage_key')
  final String storageKey;

  Map<String, Object?> toJson() => _$PhotoConfirmInToJson(this);
}
