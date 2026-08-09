// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_application_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterApplicationCreate _$CenterApplicationCreateFromJson(
  Map<String, dynamic> json,
) => CenterApplicationCreate(
  centerName: json['center_name'] as String,
  contactEmail: json['contact_email'] as String,
  contactName: json['contact_name'] as String,
  countryCode: json['country_code'] as String,
  address: json['address'] as String?,
  backingOrg: json['backing_org'] as String?,
  contactPhone: json['contact_phone'] as String?,
  message: json['message'] as String?,
  socialUrl: json['social_url'] as String?,
  stateName: json['state_name'] as String?,
);

Map<String, dynamic> _$CenterApplicationCreateToJson(
  CenterApplicationCreate instance,
) => <String, dynamic>{
  'address': instance.address,
  'backing_org': instance.backingOrg,
  'center_name': instance.centerName,
  'contact_email': instance.contactEmail,
  'contact_name': instance.contactName,
  'contact_phone': instance.contactPhone,
  'country_code': instance.countryCode,
  'message': instance.message,
  'social_url': instance.socialUrl,
  'state_name': instance.stateName,
};
