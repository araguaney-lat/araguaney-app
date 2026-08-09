// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_out.g.dart';

@JsonSerializable()
class UserOut {
  const UserOut({
    required this.avatarUrl,
    required this.centerId,
    required this.centerRole,
    required this.countryCode,
    required this.email,
    required this.fullName,
    required this.id,
    required this.isActive,
    required this.mustAcceptTerms,
    required this.role,
    required this.totpEnabled,
    required this.username,
  });

  factory UserOut.fromJson(Map<String, Object?> json) =>
      _$UserOutFromJson(json);

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'center_role')
  final String? centerRole;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String id;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'must_accept_terms')
  final bool mustAcceptTerms;
  final String role;
  @JsonKey(name: 'totp_enabled')
  final bool totpEnabled;
  final String username;

  Map<String, Object?> toJson() => _$UserOutToJson(this);
}
