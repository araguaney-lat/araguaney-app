// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'studio_user_create.g.dart';

@JsonSerializable()
class StudioUserCreate {
  const StudioUserCreate({
    required this.email,
    required this.username,
    this.centerRole = 'volunteer',
    this.centerId,
    this.countryCode,
    this.fullName,
    this.password,
  });

  factory StudioUserCreate.fromJson(Map<String, Object?> json) =>
      _$StudioUserCreateFromJson(json);

  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'center_role')
  final String centerRole;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? password;
  final String username;

  Map<String, Object?> toJson() => _$StudioUserCreateToJson(this);
}
