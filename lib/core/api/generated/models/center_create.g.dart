// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterCreate _$CenterCreateFromJson(Map<String, dynamic> json) => CenterCreate(
  name: json['name'] as String,
  address: json['address'] as String?,
  contactEmail: json['contact_email'] as String?,
  contactName: json['contact_name'] as String?,
  contactPhone: json['contact_phone'] as String?,
  countryCode: json['country_code'] as String?,
  legalName: json['legal_name'] as String?,
  stateName: json['state_name'] as String?,
  taxId: json['tax_id'] as String?,
);

Map<String, dynamic> _$CenterCreateToJson(CenterCreate instance) =>
    <String, dynamic>{
      'address': instance.address,
      'contact_email': instance.contactEmail,
      'contact_name': instance.contactName,
      'contact_phone': instance.contactPhone,
      'country_code': instance.countryCode,
      'legal_name': instance.legalName,
      'name': instance.name,
      'state_name': instance.stateName,
      'tax_id': instance.taxId,
    };
