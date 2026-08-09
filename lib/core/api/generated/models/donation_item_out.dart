// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'donation_item_out.g.dart';

@JsonSerializable()
class DonationItemOut {
  const DonationItemOut({
    required this.addedBy,
    required this.freeText,
    required this.id,
    required this.productTypeId,
    required this.quantity,
    required this.receptionStatus,
    required this.unit,
  });

  factory DonationItemOut.fromJson(Map<String, Object?> json) =>
      _$DonationItemOutFromJson(json);

  @JsonKey(name: 'added_by')
  final String addedBy;
  @JsonKey(name: 'free_text')
  final String? freeText;
  final String id;
  @JsonKey(name: 'product_type_id')
  final String? productTypeId;
  final int quantity;
  @JsonKey(name: 'reception_status')
  final String? receptionStatus;
  final String unit;

  Map<String, Object?> toJson() => _$DonationItemOutToJson(this);
}
