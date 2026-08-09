// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'transfer_out.g.dart';

@JsonSerializable()
class TransferOut {
  const TransferOut({
    required this.createdAt,
    required this.fromCenterId,
    required this.id,
    required this.initiatedBy,
    required this.notes,
    required this.status,
    required this.toCenterId,
    required this.updatedAt,
  });

  factory TransferOut.fromJson(Map<String, Object?> json) =>
      _$TransferOutFromJson(json);

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
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

  Map<String, Object?> toJson() => _$TransferOutToJson(this);
}
