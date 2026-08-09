// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'token.g.dart';

@JsonSerializable()
class Token {
  const Token({
    required this.accessToken,
    this.mustAcceptTerms = false,
    this.mustChangePassword = false,
    this.tokenType = 'bearer',
    this.centerId,
    this.centerRole,
    this.refreshToken,
    this.role,
  });

  factory Token.fromJson(Map<String, Object?> json) => _$TokenFromJson(json);

  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'center_role')
  final String? centerRole;
  @JsonKey(name: 'must_accept_terms')
  final bool mustAcceptTerms;
  @JsonKey(name: 'must_change_password')
  final bool mustChangePassword;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final String? role;
  @JsonKey(name: 'token_type')
  final String tokenType;

  Map<String, Object?> toJson() => _$TokenToJson(this);
}
