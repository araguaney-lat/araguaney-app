// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegistrationOut _$RegistrationOutFromJson(Map<String, dynamic> json) =>
    RegistrationOut(
      message: json['message'] as String,
      accessToken: json['access_token'] as String?,
    );

Map<String, dynamic> _$RegistrationOutToJson(RegistrationOut instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'message': instance.message,
    };
