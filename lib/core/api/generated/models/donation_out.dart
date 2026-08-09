// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'donation_item_out.dart';
import 'donation_photo_out.dart';

part 'donation_out.g.dart';

@JsonSerializable()
class DonationOut {
  const DonationOut({
    required this.code,
    required this.createdAt,
    required this.id,
    required this.intendedCampaignId,
    required this.intendedCenterId,
    required this.notes,
    required this.receivedCenterId,
    required this.registeredAt,
    required this.status,
    this.atypicalVolume = false,
    this.items = const [],
    this.photos = const [],
  });

  factory DonationOut.fromJson(Map<String, Object?> json) =>
      _$DonationOutFromJson(json);

  @JsonKey(name: 'atypical_volume')
  final bool atypicalVolume;
  final String code;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'intended_campaign_id')
  final String? intendedCampaignId;
  @JsonKey(name: 'intended_center_id')
  final String? intendedCenterId;
  final List<DonationItemOut> items;
  final String? notes;
  final List<DonationPhotoOut> photos;
  @JsonKey(name: 'received_center_id')
  final String? receivedCenterId;
  @JsonKey(name: 'registered_at')
  final DateTime? registeredAt;
  final String status;

  Map<String, Object?> toJson() => _$DonationOutToJson(this);
}
