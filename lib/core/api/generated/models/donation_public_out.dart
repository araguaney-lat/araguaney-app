// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'donation_item_out.dart';

part 'donation_public_out.g.dart';

/// Ficha pública del QR: estado y contenido, **sin un solo dato del donante**.
@JsonSerializable()
class DonationPublicOut {
  const DonationPublicOut({
    required this.code,
    required this.status,
    this.items = const [],
  });

  factory DonationPublicOut.fromJson(Map<String, Object?> json) =>
      _$DonationPublicOutFromJson(json);

  final String code;
  final List<DonationItemOut> items;
  final String status;

  Map<String, Object?> toJson() => _$DonationPublicOutToJson(this);
}
