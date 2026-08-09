// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_application_create.g.dart';

/// Public submission — the applicant is the prospective coordinator.
@JsonSerializable()
class CenterApplicationCreate {
  const CenterApplicationCreate({
    required this.centerName,
    required this.contactEmail,
    required this.contactName,
    required this.countryCode,
    this.address,
    this.backingOrg,
    this.contactPhone,
    this.message,
    this.socialUrl,
    this.stateName,
  });

  factory CenterApplicationCreate.fromJson(Map<String, Object?> json) =>
      _$CenterApplicationCreateFromJson(json);

  final String? address;
  @JsonKey(name: 'backing_org')
  final String? backingOrg;
  @JsonKey(name: 'center_name')
  final String centerName;
  @JsonKey(name: 'contact_email')
  final String contactEmail;
  @JsonKey(name: 'contact_name')
  final String contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'country_code')
  final String countryCode;
  final String? message;
  @JsonKey(name: 'social_url')
  final String? socialUrl;
  @JsonKey(name: 'state_name')
  final String? stateName;

  Map<String, Object?> toJson() => _$CenterApplicationCreateToJson(this);
}
