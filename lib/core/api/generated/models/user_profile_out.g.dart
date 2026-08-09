// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileOut _$UserProfileOutFromJson(Map<String, dynamic> json) =>
    UserProfileOut(
      avatarUrl: json['avatar_url'] as String?,
      campaigns: (json['campaigns'] as List<dynamic>)
          .map((e) => CampaignSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      centerId: json['center_id'] as String?,
      centerName: json['center_name'] as String?,
      centerRole: json['center_role'] as String?,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      id: json['id'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$UserProfileOutToJson(UserProfileOut instance) =>
    <String, dynamic>{
      'avatar_url': instance.avatarUrl,
      'campaigns': instance.campaigns,
      'center_id': instance.centerId,
      'center_name': instance.centerName,
      'center_role': instance.centerRole,
      'email': instance.email,
      'full_name': instance.fullName,
      'id': instance.id,
      'username': instance.username,
    };
