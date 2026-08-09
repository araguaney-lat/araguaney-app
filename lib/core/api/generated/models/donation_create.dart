// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'donation_item_input.dart';
import 'donor_input.dart';

part 'donation_create.g.dart';

@JsonSerializable()
class DonationCreate {
  const DonationCreate({
    required this.donor,
    required this.items,
    this.termsAccepted = false,
    this.intendedCampaignId,
    this.intendedCenterId,
    this.notes,
  });

  factory DonationCreate.fromJson(Map<String, Object?> json) =>
      _$DonationCreateFromJson(json);

  final DonorInput donor;
  @JsonKey(name: 'intended_campaign_id')
  final String? intendedCampaignId;
  @JsonKey(name: 'intended_center_id')
  final String? intendedCenterId;
  final List<DonationItemInput> items;
  final String? notes;
  @JsonKey(name: 'terms_accepted')
  final bool termsAccepted;

  Map<String, Object?> toJson() => _$DonationCreateToJson(this);
}
