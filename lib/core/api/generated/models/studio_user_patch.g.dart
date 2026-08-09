// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'studio_user_patch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudioUserPatch _$StudioUserPatchFromJson(Map<String, dynamic> json) =>
    StudioUserPatch(
      centerId: json['center_id'] as String?,
      centerRole: json['center_role'] as String?,
      countryCode: json['country_code'] as String?,
      fullName: json['full_name'] as String?,
      isActive: json['is_active'] as bool?,
    );

Map<String, dynamic> _$StudioUserPatchToJson(StudioUserPatch instance) =>
    <String, dynamic>{
      'center_id': instance.centerId,
      'center_role': instance.centerRole,
      'country_code': instance.countryCode,
      'full_name': instance.fullName,
      'is_active': instance.isActive,
    };
