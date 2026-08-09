// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'logout_request.g.dart';

@JsonSerializable()
class LogoutRequest {
  const LogoutRequest({this.refreshToken});

  factory LogoutRequest.fromJson(Map<String, Object?> json) =>
      _$LogoutRequestFromJson(json);

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  Map<String, Object?> toJson() => _$LogoutRequestToJson(this);
}
