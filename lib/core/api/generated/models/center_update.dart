// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_update.g.dart';

@JsonSerializable()
class CenterUpdate {
  const CenterUpdate({
    this.address,
    this.contactEmail,
    this.contactName,
    this.contactPhone,
    this.countryCode,
    this.isActive,
    this.legalName,
    this.name,
    this.stateName,
    this.taxId,
  });

  factory CenterUpdate.fromJson(Map<String, Object?> json) =>
      _$CenterUpdateFromJson(json);

  final String? address;
  @JsonKey(name: 'contact_email')
  final String? contactEmail;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String? name;
  @JsonKey(name: 'state_name')
  final String? stateName;
  @JsonKey(name: 'tax_id')
  final String? taxId;

  Map<String, Object?> toJson() => _$CenterUpdateToJson(this);
}
