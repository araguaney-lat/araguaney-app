// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'campaign_summary.dart';

part 'user_profile_out.g.dart';

@JsonSerializable()
class UserProfileOut {
  const UserProfileOut({
    required this.avatarUrl,
    required this.campaigns,
    required this.centerId,
    required this.centerName,
    required this.centerRole,
    required this.email,
    required this.fullName,
    required this.id,
    required this.username,
  });

  factory UserProfileOut.fromJson(Map<String, Object?> json) =>
      _$UserProfileOutFromJson(json);

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final List<CampaignSummary> campaigns;
  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'center_name')
  final String? centerName;
  @JsonKey(name: 'center_role')
  final String? centerRole;
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String id;
  final String username;

  Map<String, Object?> toJson() => _$UserProfileOutToJson(this);
}
