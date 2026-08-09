// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Token _$TokenFromJson(Map<String, dynamic> json) => Token(
  accessToken: json['access_token'] as String,
  mustAcceptTerms: json['must_accept_terms'] as bool? ?? false,
  mustChangePassword: json['must_change_password'] as bool? ?? false,
  tokenType: json['token_type'] as String? ?? 'bearer',
  centerId: json['center_id'] as String?,
  centerRole: json['center_role'] as String?,
  refreshToken: json['refresh_token'] as String?,
  role: json['role'] as String?,
);

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'center_id': instance.centerId,
  'center_role': instance.centerRole,
  'must_accept_terms': instance.mustAcceptTerms,
  'must_change_password': instance.mustChangePassword,
  'refresh_token': instance.refreshToken,
  'role': instance.role,
  'token_type': instance.tokenType,
};
