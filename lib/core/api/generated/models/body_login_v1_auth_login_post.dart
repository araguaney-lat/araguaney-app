// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'body_login_v1_auth_login_post.g.dart';

@JsonSerializable()
class BodyLoginV1AuthLoginPost {
  const BodyLoginV1AuthLoginPost({
    required this.password,
    required this.username,
    this.scope = '',
    this.clientId,
    this.clientSecret,
    this.grantType,
  });

  factory BodyLoginV1AuthLoginPost.fromJson(Map<String, Object?> json) =>
      _$BodyLoginV1AuthLoginPostFromJson(json);

  @JsonKey(name: 'client_id')
  final String? clientId;
  @JsonKey(name: 'client_secret')
  final String? clientSecret;
  @JsonKey(name: 'grant_type')
  final String? grantType;
  final String password;
  final String scope;
  final String username;

  Map<String, Object?> toJson() => _$BodyLoginV1AuthLoginPostToJson(this);
}
