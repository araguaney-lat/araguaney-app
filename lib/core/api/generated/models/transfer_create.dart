// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'transfer_create.g.dart';

@JsonSerializable()
class TransferCreate {
  const TransferCreate({
    required this.boxIds,
    required this.fromCenterId,
    required this.toCenterId,
    this.notes,
  });

  factory TransferCreate.fromJson(Map<String, Object?> json) =>
      _$TransferCreateFromJson(json);

  @JsonKey(name: 'box_ids')
  final List<String> boxIds;
  @JsonKey(name: 'from_center_id')
  final String fromCenterId;
  final String? notes;
  @JsonKey(name: 'to_center_id')
  final String toCenterId;

  Map<String, Object?> toJson() => _$TransferCreateToJson(this);
}
