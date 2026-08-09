// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'transfer_event_out.g.dart';

@JsonSerializable()
class TransferEventOut {
  const TransferEventOut({
    required this.fromStatus,
    required this.id,
    required this.note,
    required this.toStatus,
    required this.transferId,
    required this.ts,
    required this.userId,
  });

  factory TransferEventOut.fromJson(Map<String, Object?> json) =>
      _$TransferEventOutFromJson(json);

  @JsonKey(name: 'from_status')
  final String? fromStatus;
  final String id;
  final String? note;
  @JsonKey(name: 'to_status')
  final String toStatus;
  @JsonKey(name: 'transfer_id')
  final String transferId;
  final DateTime ts;
  @JsonKey(name: 'user_id')
  final String? userId;

  Map<String, Object?> toJson() => _$TransferEventOutToJson(this);
}
