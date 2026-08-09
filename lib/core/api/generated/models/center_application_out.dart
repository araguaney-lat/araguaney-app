// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'center_application_out.g.dart';

/// Queue view for reviewers (national_admin / superadmin).
@JsonSerializable()
class CenterApplicationOut {
  const CenterApplicationOut({
    required this.address,
    required this.backingOrg,
    required this.centerName,
    required this.contactEmail,
    required this.contactName,
    required this.contactPhone,
    required this.countryCode,
    required this.createdAt,
    required this.createdCenterId,
    required this.emailVerifiedAt,
    required this.id,
    required this.message,
    required this.rejectReason,
    required this.reviewedAt,
    required this.socialUrl,
    required this.stateName,
    required this.status,
  });

  factory CenterApplicationOut.fromJson(Map<String, Object?> json) =>
      _$CenterApplicationOutFromJson(json);

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
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'created_center_id')
  final String? createdCenterId;
  @JsonKey(name: 'email_verified_at')
  final DateTime? emailVerifiedAt;
  final String id;
  final String? message;
  @JsonKey(name: 'reject_reason')
  final String? rejectReason;
  @JsonKey(name: 'reviewed_at')
  final DateTime? reviewedAt;
  @JsonKey(name: 'social_url')
  final String? socialUrl;
  @JsonKey(name: 'state_name')
  final String? stateName;
  final String status;

  Map<String, Object?> toJson() => _$CenterApplicationOutToJson(this);
}
