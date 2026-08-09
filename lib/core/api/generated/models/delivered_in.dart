// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'delivered_in.g.dart';

@JsonSerializable()
class DeliveredIn {
  const DeliveredIn({this.deliveredAt, this.note});

  factory DeliveredIn.fromJson(Map<String, Object?> json) =>
      _$DeliveredInFromJson(json);

  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  final String? note;

  Map<String, Object?> toJson() => _$DeliveredInToJson(this);
}
