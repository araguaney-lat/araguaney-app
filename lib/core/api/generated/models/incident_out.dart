// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'incident_out.g.dart';

@JsonSerializable()
class IncidentOut {
  const IncidentOut({
    required this.boxId,
    required this.createdAt,
    required this.description,
    required this.id,
    required this.palletId,
    required this.resolutionNote,
    required this.resolvedAt,
    required this.shipmentId,
    required this.status,
    required this.type,
  });

  factory IncidentOut.fromJson(Map<String, Object?> json) =>
      _$IncidentOutFromJson(json);

  @JsonKey(name: 'box_id')
  final String? boxId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String description;
  final String id;
  @JsonKey(name: 'pallet_id')
  final String? palletId;
  @JsonKey(name: 'resolution_note')
  final String? resolutionNote;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final String status;
  final String type;

  Map<String, Object?> toJson() => _$IncidentOutToJson(this);
}
