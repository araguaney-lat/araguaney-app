// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'center_application_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CenterApplicationOut _$CenterApplicationOutFromJson(
  Map<String, dynamic> json,
) => CenterApplicationOut(
  address: json['address'] as String?,
  backingOrg: json['backing_org'] as String?,
  centerName: json['center_name'] as String,
  contactEmail: json['contact_email'] as String,
  contactName: json['contact_name'] as String,
  contactPhone: json['contact_phone'] as String?,
  countryCode: json['country_code'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  createdCenterId: json['created_center_id'] as String?,
  emailVerifiedAt: json['email_verified_at'] == null
      ? null
      : DateTime.parse(json['email_verified_at'] as String),
  id: json['id'] as String,
  message: json['message'] as String?,
  rejectReason: json['reject_reason'] as String?,
  reviewedAt: json['reviewed_at'] == null
      ? null
      : DateTime.parse(json['reviewed_at'] as String),
  socialUrl: json['social_url'] as String?,
  stateName: json['state_name'] as String?,
  status: json['status'] as String,
);

Map<String, dynamic> _$CenterApplicationOutToJson(
  CenterApplicationOut instance,
) => <String, dynamic>{
  'address': instance.address,
  'backing_org': instance.backingOrg,
  'center_name': instance.centerName,
  'contact_email': instance.contactEmail,
  'contact_name': instance.contactName,
  'contact_phone': instance.contactPhone,
  'country_code': instance.countryCode,
  'created_at': instance.createdAt.toIso8601String(),
  'created_center_id': instance.createdCenterId,
  'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
  'id': instance.id,
  'message': instance.message,
  'reject_reason': instance.rejectReason,
  'reviewed_at': instance.reviewedAt?.toIso8601String(),
  'social_url': instance.socialUrl,
  'state_name': instance.stateName,
  'status': instance.status,
};
