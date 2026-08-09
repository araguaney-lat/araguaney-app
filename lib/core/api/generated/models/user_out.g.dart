// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserOut _$UserOutFromJson(Map<String, dynamic> json) => UserOut(
  avatarUrl: json['avatar_url'] as String?,
  centerId: json['center_id'] as String?,
  centerRole: json['center_role'] as String?,
  countryCode: json['country_code'] as String?,
  email: json['email'] as String,
  fullName: json['full_name'] as String?,
  id: json['id'] as String,
  isActive: json['is_active'] as bool,
  mustAcceptTerms: json['must_accept_terms'] as bool,
  role: json['role'] as String,
  totpEnabled: json['totp_enabled'] as bool,
  username: json['username'] as String,
);

Map<String, dynamic> _$UserOutToJson(UserOut instance) => <String, dynamic>{
  'avatar_url': instance.avatarUrl,
  'center_id': instance.centerId,
  'center_role': instance.centerRole,
  'country_code': instance.countryCode,
  'email': instance.email,
  'full_name': instance.fullName,
  'id': instance.id,
  'is_active': instance.isActive,
  'must_accept_terms': instance.mustAcceptTerms,
  'role': instance.role,
  'totp_enabled': instance.totpEnabled,
  'username': instance.username,
};
