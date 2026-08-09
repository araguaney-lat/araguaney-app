// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_schemas_box_box_out.dart';
import 'transfer_event_out.dart';

part 'transfer_detail_out.g.dart';

@JsonSerializable()
class TransferDetailOut {
  const TransferDetailOut({
    required this.boxes,
    required this.createdAt,
    required this.events,
    required this.fromCenterId,
    required this.id,
    required this.initiatedBy,
    required this.notes,
    required this.status,
    required this.toCenterId,
    required this.updatedAt,
  });

  factory TransferDetailOut.fromJson(Map<String, Object?> json) =>
      _$TransferDetailOutFromJson(json);

  final List<AppSchemasBoxBoxOut> boxes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final List<TransferEventOut> events;
  @JsonKey(name: 'from_center_id')
  final String fromCenterId;
  final String id;
  @JsonKey(name: 'initiated_by')
  final String? initiatedBy;
  final String? notes;
  final String status;
  @JsonKey(name: 'to_center_id')
  final String toCenterId;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$TransferDetailOutToJson(this);
}
