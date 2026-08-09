// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reset_password_request.g.dart';

@JsonSerializable()
class ResetPasswordRequest {
  const ResetPasswordRequest({required this.newPassword, required this.token});

  factory ResetPasswordRequest.fromJson(Map<String, Object?> json) =>
      _$ResetPasswordRequestFromJson(json);

  @JsonKey(name: 'new_password')
  final String newPassword;
  final String token;

  Map<String, Object?> toJson() => _$ResetPasswordRequestToJson(this);
}
