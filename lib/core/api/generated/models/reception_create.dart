// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reception_exception_in.dart';
import 'reception_pallet_weight_in.dart';

part 'reception_create.g.dart';

@JsonSerializable()
class ReceptionCreate {
  const ReceptionCreate({
    this.exceptions = const [],
    this.palletWeights = const [],
    this.consigneeName,
    this.notes,
  });

  factory ReceptionCreate.fromJson(Map<String, Object?> json) =>
      _$ReceptionCreateFromJson(json);

  @JsonKey(name: 'consignee_name')
  final String? consigneeName;
  final List<ReceptionExceptionIn> exceptions;
  final String? notes;
  @JsonKey(name: 'pallet_weights')
  final List<ReceptionPalletWeightIn> palletWeights;

  Map<String, Object?> toJson() => _$ReceptionCreateToJson(this);
}
