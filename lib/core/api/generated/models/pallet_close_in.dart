// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'pallet_close_in.g.dart';

/// Pesaje al cerrar. Todo opcional: una báscula descompuesta no puede.
/// impedir que se cierre una tarima ya armada.
@JsonSerializable()
class PalletCloseIn {
  const PalletCloseIn({this.grossWeightKg, this.heightCm});

  factory PalletCloseIn.fromJson(Map<String, Object?> json) =>
      _$PalletCloseInFromJson(json);

  @JsonKey(name: 'gross_weight_kg')
  final dynamic grossWeightKg;
  @JsonKey(name: 'height_cm')
  final int? heightCm;

  Map<String, Object?> toJson() => _$PalletCloseInToJson(this);
}
