// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_create.g.dart';

@JsonSerializable()
class CenterCreate {
  const CenterCreate({
    required this.name,
    this.address,
    this.contactEmail,
    this.contactName,
    this.contactPhone,
    this.countryCode,
    this.legalName,
    this.stateName,
    this.taxId,
  });

  factory CenterCreate.fromJson(Map<String, Object?> json) =>
      _$CenterCreateFromJson(json);

  final String? address;
  @JsonKey(name: 'contact_email')
  final String? contactEmail;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String name;
  @JsonKey(name: 'state_name')
  final String? stateName;
  @JsonKey(name: 'tax_id')
  final String? taxId;

  Map<String, Object?> toJson() => _$CenterCreateToJson(this);
}
