// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donor_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonorInput _$DonorInputFromJson(Map<String, dynamic> json) => DonorInput(
  firstName: json['first_name'] as String,
  lastName: json['last_name'] as String,
  email: json['email'] as String?,
  legalName: json['legal_name'] as String?,
  phone: json['phone'] as String?,
  donorType: json['donor_type'] as String? ?? 'fisica',
);

Map<String, dynamic> _$DonorInputToJson(DonorInput instance) =>
    <String, dynamic>{
      'donor_type': instance.donorType,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'legal_name': instance.legalName,
      'phone': instance.phone,
    };
