// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'donor_out.g.dart';

@JsonSerializable()
class DonorOut {
  const DonorOut({
    required this.createdAt,
    required this.donorType,
    required this.email,
    required this.firstName,
    required this.id,
    required this.lastName,
    required this.legalName,
    required this.phone,
  });

  factory DonorOut.fromJson(Map<String, Object?> json) =>
      _$DonorOutFromJson(json);

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'donor_type')
  final String donorType;
  final String? email;
  @JsonKey(name: 'first_name')
  final String firstName;
  final String id;
  @JsonKey(name: 'last_name')
  final String lastName;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String? phone;

  Map<String, Object?> toJson() => _$DonorOutToJson(this);
}
