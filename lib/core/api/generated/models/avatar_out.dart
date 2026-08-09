// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'avatar_out.g.dart';

@JsonSerializable()
class AvatarOut {
  const AvatarOut({required this.avatarUrl});

  factory AvatarOut.fromJson(Map<String, Object?> json) =>
      _$AvatarOutFromJson(json);

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  Map<String, Object?> toJson() => _$AvatarOutToJson(this);
}
