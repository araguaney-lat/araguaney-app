// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'donation_item_input.dart';

part 'items_in.g.dart';

@JsonSerializable()
class ItemsIn {
  const ItemsIn({required this.items});

  factory ItemsIn.fromJson(Map<String, Object?> json) =>
      _$ItemsInFromJson(json);

  final List<DonationItemInput> items;

  Map<String, Object?> toJson() => _$ItemsInToJson(this);
}
