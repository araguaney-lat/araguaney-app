// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'totp_confirm_in.g.dart';

@JsonSerializable()
class TotpConfirmIn {
  const TotpConfirmIn({required this.code});

  factory TotpConfirmIn.fromJson(Map<String, Object?> json) =>
      _$TotpConfirmInFromJson(json);

  final String code;

  Map<String, Object?> toJson() => _$TotpConfirmInToJson(this);
}
