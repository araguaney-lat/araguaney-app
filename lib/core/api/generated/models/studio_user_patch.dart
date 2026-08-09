// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'studio_user_patch.g.dart';

@JsonSerializable()
class StudioUserPatch {
  const StudioUserPatch({
    this.centerId,
    this.centerRole,
    this.countryCode,
    this.fullName,
    this.isActive,
  });

  factory StudioUserPatch.fromJson(Map<String, Object?> json) =>
      _$StudioUserPatchFromJson(json);

  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'center_role')
  final String? centerRole;
  @JsonKey(name: 'country_code')
  final String? countryCode;
  @JsonKey(name: 'full_name')
  final String? fullName;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  Map<String, Object?> toJson() => _$StudioUserPatchToJson(this);
}
