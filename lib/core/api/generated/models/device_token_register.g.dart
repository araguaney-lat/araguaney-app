// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_token_register.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTokenRegister _$DeviceTokenRegisterFromJson(Map<String, dynamic> json) =>
    DeviceTokenRegister(
      platform: DeviceTokenRegisterPlatform.fromJson(
        json['platform'] as String,
      ),
      token: json['token'] as String,
      appVersion: json['app_version'] as String?,
    );

Map<String, dynamic> _$DeviceTokenRegisterToJson(
  DeviceTokenRegister instance,
) => <String, dynamic>{
  'app_version': instance.appVersion,
  'platform': instance.platform,
  'token': instance.token,
};
