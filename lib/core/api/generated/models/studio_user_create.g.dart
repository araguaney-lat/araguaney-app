// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_user_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudioUserCreate _$StudioUserCreateFromJson(Map<String, dynamic> json) =>
    StudioUserCreate(
      email: json['email'] as String,
      username: json['username'] as String,
      centerRole: json['center_role'] as String? ?? 'volunteer',
      centerId: json['center_id'] as String?,
      countryCode: json['country_code'] as String?,
      fullName: json['full_name'] as String?,
      password: json['password'] as String?,
    );

Map<String, dynamic> _$StudioUserCreateToJson(StudioUserCreate instance) =>
    <String, dynamic>{
      'center_id': instance.centerId,
      'center_role': instance.centerRole,
      'country_code': instance.countryCode,
      'email': instance.email,
      'full_name': instance.fullName,
      'password': instance.password,
      'username': instance.username,
    };
