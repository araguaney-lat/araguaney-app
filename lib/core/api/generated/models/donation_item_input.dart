// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'donation_item_input.g.dart';

/// Un renglón: del catálogo o texto libre, nunca ambos.
///
/// El texto libre no es una concesión, es el punto: un particular escribe.
/// "20 latas de atún" y el centro lo mapea al catálogo cuando recibe.
@JsonSerializable()
class DonationItemInput {
  const DonationItemInput({
    required this.quantity,
    required this.unit,
    this.freeText,
    this.productTypeId,
  });

  factory DonationItemInput.fromJson(Map<String, Object?> json) =>
      _$DonationItemInputFromJson(json);

  @JsonKey(name: 'free_text')
  final String? freeText;
  @JsonKey(name: 'product_type_id')
  final String? productTypeId;
  final int quantity;
  final String unit;

  Map<String, Object?> toJson() => _$DonationItemInputToJson(this);
}
