// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserInvite _$UserInviteFromJson(Map<String, dynamic> json) => UserInvite(
  email: json['email'] as String,
  username: json['username'] as String,
  countryCode: json['country_code'] as String?,
  fullName: json['full_name'] as String?,
  centerRole: json['center_role'] as String? ?? 'volunteer',
);

Map<String, dynamic> _$UserInviteToJson(UserInvite instance) =>
    <String, dynamic>{
      'center_role': instance.centerRole,
      'country_code': instance.countryCode,
      'email': instance.email,
      'full_name': instance.fullName,
      'username': instance.username,
    };
