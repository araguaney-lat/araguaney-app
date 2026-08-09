// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_out.g.dart';

@JsonSerializable()
class CenterOut {
  const CenterOut({
    required this.address,
    required this.contactEmail,
    required this.contactName,
    required this.contactPhone,
    required this.countryCode,
    required this.createdAt,
    required this.id,
    required this.isActive,
    required this.name,
    required this.stateName,
    this.legalName,
    this.taxId,
  });

  factory CenterOut.fromJson(Map<String, Object?> json) =>
      _$CenterOutFromJson(json);

  final String? address;
  @JsonKey(name: 'contact_email')
  final String? contactEmail;
  @JsonKey(name: 'contact_name')
  final String? contactName;
  @JsonKey(name: 'contact_phone')
  final String? contactPhone;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String name;
  @JsonKey(name: 'state_name')
  final String? stateName;
  @JsonKey(name: 'tax_id')
  final String? taxId;

  Map<String, Object?> toJson() => _$CenterOutToJson(this);
}
