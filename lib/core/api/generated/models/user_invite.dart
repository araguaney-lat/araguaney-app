// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_invite.g.dart';

@JsonSerializable()
class UserInvite {
  const UserInvite({
    required this.email,
    required this.username,
    this.countryCode,
    this.fullName,
    this.centerRole = 'volunteer',
  });

  factory UserInvite.fromJson(Map<String, Object?> json) =>
      _$UserInviteFromJson(json);

  @JsonKey(name: 'center_role')
  final String centerRole;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String username;

  Map<String, Object?> toJson() => _$UserInviteToJson(this);
}
