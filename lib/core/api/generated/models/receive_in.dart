// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'donation_item_input.dart';

part 'receive_in.g.dart';

/// Solo las excepciones: lo que no viene marcado se da por recibido.
@JsonSerializable()
class ReceiveIn {
  const ReceiveIn({this.centerId, this.extras, this.results});

  factory ReceiveIn.fromJson(Map<String, Object?> json) =>
      _$ReceiveInFromJson(json);

  @JsonKey(name: 'center_id')
  final String? centerId;
  final List<DonationItemInput>? extras;
  final Map<String, String>? results;

  Map<String, Object?> toJson() => _$ReceiveInToJson(this);
}
