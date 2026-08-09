// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reception_pallet_weight_out.g.dart';

@JsonSerializable()
class ReceptionPalletWeightOut {
  const ReceptionPalletWeightOut({
    required this.grossWeightKg,
    required this.palletId,
  });

  factory ReceptionPalletWeightOut.fromJson(Map<String, Object?> json) =>
      _$ReceptionPalletWeightOutFromJson(json);

  @JsonKey(name: 'gross_weight_kg')
  final String grossWeightKg;
  @JsonKey(name: 'pallet_id')
  final String palletId;

  Map<String, Object?> toJson() => _$ReceptionPalletWeightOutToJson(this);
}
