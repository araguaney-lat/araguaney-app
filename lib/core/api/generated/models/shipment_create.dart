// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shipment_create.g.dart';

@JsonSerializable()
class ShipmentCreate {
  const ShipmentCreate({
    this.destination = 'Venezuela',
    this.campaignId,
    this.carrier,
    this.centerId,
    this.heightProfile,
    this.notes,
    this.reference,
  });

  factory ShipmentCreate.fromJson(Map<String, Object?> json) =>
      _$ShipmentCreateFromJson(json);

  @JsonKey(name: 'campaign_id')
  final String? campaignId;
  final String? carrier;
  @JsonKey(name: 'center_id')
  final String? centerId;
  final String destination;
  @JsonKey(name: 'height_profile')
  final String? heightProfile;
  final String? notes;
  final String? reference;

  Map<String, Object?> toJson() => _$ShipmentCreateToJson(this);
}
