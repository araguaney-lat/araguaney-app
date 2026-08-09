// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'transfer_reject.g.dart';

@JsonSerializable()
class TransferReject {
  const TransferReject({this.reason});

  factory TransferReject.fromJson(Map<String, Object?> json) =>
      _$TransferRejectFromJson(json);

  final String? reason;

  Map<String, Object?> toJson() => _$TransferRejectToJson(this);
}
