// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donor_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonorOut _$DonorOutFromJson(Map<String, dynamic> json) => DonorOut(
  createdAt: DateTime.parse(json['created_at'] as String),
  donorType: json['donor_type'] as String,
  email: json['email'] as String?,
  firstName: json['first_name'] as String,
  id: json['id'] as String,
  lastName: json['last_name'] as String,
  legalName: json['legal_name'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$DonorOutToJson(DonorOut instance) => <String, dynamic>{
  'created_at': instance.createdAt.toIso8601String(),
  'donor_type': instance.donorType,
  'email': instance.email,
  'first_name': instance.firstName,
  'id': instance.id,
  'last_name': instance.lastName,
  'legal_name': instance.legalName,
  'phone': instance.phone,
};
