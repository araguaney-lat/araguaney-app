// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'reception_line_out.dart';
import 'reception_pallet_weight_out.dart';
import 'shrinkage_out.dart';

part 'reception_out.g.dart';

@JsonSerializable()
class ReceptionOut {
  const ReceptionOut({
    required this.consigneeName,
    required this.id,
    required this.notes,
    required this.receivedAt,
    required this.shipmentId,
    required this.shrinkage,
    this.lines = const [],
    this.palletWeights = const [],
  });

  factory ReceptionOut.fromJson(Map<String, Object?> json) =>
      _$ReceptionOutFromJson(json);

  @JsonKey(name: 'consignee_name')
  final String? consigneeName;
  final String id;
  final List<ReceptionLineOut> lines;
  final String? notes;
  @JsonKey(name: 'pallet_weights')
  final List<ReceptionPalletWeightOut> palletWeights;
  @JsonKey(name: 'received_at')
  final DateTime receivedAt;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final ShrinkageOut shrinkage;

  Map<String, Object?> toJson() => _$ReceptionOutToJson(this);
}
