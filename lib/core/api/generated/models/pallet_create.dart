// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pallet_create.g.dart';

@JsonSerializable()
class PalletCreate {
  const PalletCreate({this.centerId, this.notes, this.tareWeightKg});

  factory PalletCreate.fromJson(Map<String, Object?> json) =>
      _$PalletCreateFromJson(json);

  @JsonKey(name: 'center_id')
  final String? centerId;
  final String? notes;
  @JsonKey(name: 'tare_weight_kg')
  final dynamic tareWeightKg;

  Map<String, Object?> toJson() => _$PalletCreateToJson(this);
}
