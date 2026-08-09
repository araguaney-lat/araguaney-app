// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_member_out.g.dart';

@JsonSerializable()
class CampaignMemberOut {
  const CampaignMemberOut({
    required this.centerId,
    required this.centerRole,
    required this.email,
    required this.fullName,
    required this.id,
    required this.isActive,
    required this.username,
  });

  factory CampaignMemberOut.fromJson(Map<String, Object?> json) =>
      _$CampaignMemberOutFromJson(json);

  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'center_role')
  final String? centerRole;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String id;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final String username;

  Map<String, Object?> toJson() => _$CampaignMemberOutToJson(this);
}
