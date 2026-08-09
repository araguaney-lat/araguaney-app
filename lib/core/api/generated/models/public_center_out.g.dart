// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_center_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicCenterOut _$PublicCenterOutFromJson(Map<String, dynamic> json) =>
    PublicCenterOut(
      countryCode: json['country_code'] as String?,
      id: json['id'] as String,
      name: json['name'] as String,
      stateName: json['state_name'] as String?,
    );

Map<String, dynamic> _$PublicCenterOutToJson(PublicCenterOut instance) =>
    <String, dynamic>{
      'country_code': instance.countryCode,
      'id': instance.id,
      'name': instance.name,
      'state_name': instance.stateName,
    };
