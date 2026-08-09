// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'pallet_detail_out.dart';

part 'shipment_detail_out.g.dart';

@JsonSerializable()
class ShipmentDetailOut {
  const ShipmentDetailOut({
    required this.campaignId,
    required this.carrier,
    required this.centerId,
    required this.closedAt,
    required this.createdAt,
    required this.destination,
    required this.id,
    required this.notes,
    required this.pallets,
    required this.reference,
    required this.shippedAt,
    required this.status,
    this.heightWarnings = const [],
    this.deliveredAt,
    this.heightProfile,
    this.reconciledAt,
  });

  factory ShipmentDetailOut.fromJson(Map<String, Object?> json) =>
      _$ShipmentDetailOutFromJson(json);

  @JsonKey(name: 'campaign_id')
  final String? campaignId;
  final String? carrier;
  @JsonKey(name: 'center_id')
  final String? centerId;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  final String destination;
  @JsonKey(name: 'height_profile')
  final String? heightProfile;
  @JsonKey(name: 'height_warnings')
  final List<String> heightWarnings;
  final String id;
  final String? notes;
  final List<PalletDetailOut> pallets;
  @JsonKey(name: 'reconciled_at')
  final DateTime? reconciledAt;
  final String? reference;
  @JsonKey(name: 'shipped_at')
  final DateTime? shippedAt;
  final String status;

  Map<String, Object?> toJson() => _$ShipmentDetailOutToJson(this);
}
