// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterOut _$CenterOutFromJson(Map<String, dynamic> json) => CenterOut(
  address: json['address'] as String?,
  contactEmail: json['contact_email'] as String?,
  contactName: json['contact_name'] as String?,
  contactPhone: json['contact_phone'] as String?,
  countryCode: json['country_code'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  id: json['id'] as String,
  isActive: json['is_active'] as bool,
  name: json['name'] as String,
  stateName: json['state_name'] as String?,
  legalName: json['legal_name'] as String?,
  taxId: json['tax_id'] as String?,
);

Map<String, dynamic> _$CenterOutToJson(CenterOut instance) => <String, dynamic>{
  'address': instance.address,
  'contact_email': instance.contactEmail,
  'contact_name': instance.contactName,
  'contact_phone': instance.contactPhone,
  'country_code': instance.countryCode,
  'created_at': instance.createdAt.toIso8601String(),
  'id': instance.id,
  'is_active': instance.isActive,
  'legal_name': instance.legalName,
  'name': instance.name,
  'state_name': instance.stateName,
  'tax_id': instance.taxId,
};
