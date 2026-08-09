// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'campaign_member_add.g.dart';

@JsonSerializable()
class CampaignMemberAdd {
  const CampaignMemberAdd({required this.userId});

  factory CampaignMemberAdd.fromJson(Map<String, Object?> json) =>
      _$CampaignMemberAddFromJson(json);

  @JsonKey(name: 'user_id')
  final String userId;

  Map<String, Object?> toJson() => _$CampaignMemberAddToJson(this);
}
