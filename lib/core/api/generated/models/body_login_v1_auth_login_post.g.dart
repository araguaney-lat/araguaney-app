// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_login_v1_auth_login_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BodyLoginV1AuthLoginPost _$BodyLoginV1AuthLoginPostFromJson(
  Map<String, dynamic> json,
) => BodyLoginV1AuthLoginPost(
  password: json['password'] as String,
  username: json['username'] as String,
  scope: json['scope'] as String? ?? '',
  clientId: json['client_id'] as String?,
  clientSecret: json['client_secret'] as String?,
  grantType: json['grant_type'] as String?,
);

Map<String, dynamic> _$BodyLoginV1AuthLoginPostToJson(
  BodyLoginV1AuthLoginPost instance,
) => <String, dynamic>{
  'client_id': instance.clientId,
  'client_secret': instance.clientSecret,
  'grant_type': instance.grantType,
  'password': instance.password,
  'scope': instance.scope,
  'username': instance.username,
};
