// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_member_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CampaignMemberOut _$CampaignMemberOutFromJson(Map<String, dynamic> json) =>
    CampaignMemberOut(
      centerId: json['center_id'] as String?,
      centerRole: json['center_role'] as String?,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      id: json['id'] as String,
      isActive: json['is_active'] as bool,
      username: json['username'] as String,
    );

Map<String, dynamic> _$CampaignMemberOutToJson(CampaignMemberOut instance) =>
    <String, dynamic>{
      'center_id': instance.centerId,
      'center_role': instance.centerRole,
      'email': instance.email,
      'full_name': instance.fullName,
      'id': instance.id,
      'is_active': instance.isActive,
      'username': instance.username,
    };
