// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterUpdate _$CenterUpdateFromJson(Map<String, dynamic> json) => CenterUpdate(
  address: json['address'] as String?,
  contactEmail: json['contact_email'] as String?,
  contactName: json['contact_name'] as String?,
  contactPhone: json['contact_phone'] as String?,
  countryCode: json['country_code'] as String?,
  isActive: json['is_active'] as bool?,
  legalName: json['legal_name'] as String?,
  name: json['name'] as String?,
  stateName: json['state_name'] as String?,
  taxId: json['tax_id'] as String?,
);

Map<String, dynamic> _$CenterUpdateToJson(CenterUpdate instance) =>
    <String, dynamic>{
      'address': instance.address,
      'contact_email': instance.contactEmail,
      'contact_name': instance.contactName,
      'contact_phone': instance.contactPhone,
      'country_code': instance.countryCode,
      'is_active': instance.isActive,
      'legal_name': instance.legalName,
      'name': instance.name,
      'state_name': instance.stateName,
      'tax_id': instance.taxId,
    };
