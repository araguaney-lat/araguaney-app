// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'donor_input.g.dart';

@JsonSerializable()
class DonorInput {
  const DonorInput({
    required this.firstName,
    required this.lastName,
    this.email,
    this.legalName,
    this.phone,
    this.donorType = 'fisica',
  });

  factory DonorInput.fromJson(Map<String, Object?> json) =>
      _$DonorInputFromJson(json);

  @JsonKey(name: 'donor_type')
  final String donorType;
  final String? email;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  @JsonKey(name: 'legal_name')
  final String? legalName;
  final String? phone;

  Map<String, Object?> toJson() => _$DonorInputToJson(this);
}
