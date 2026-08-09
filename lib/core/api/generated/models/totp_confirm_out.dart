// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'totp_confirm_out.g.dart';

@JsonSerializable()
class TotpConfirmOut {
  const TotpConfirmOut({required this.backupCodes});

  factory TotpConfirmOut.fromJson(Map<String, Object?> json) =>
      _$TotpConfirmOutFromJson(json);

  @JsonKey(name: 'backup_codes')
  final List<String> backupCodes;

  Map<String, Object?> toJson() => _$TotpConfirmOutToJson(this);
}
