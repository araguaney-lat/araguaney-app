// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'totp_setup_out.g.dart';

@JsonSerializable()
class TotpSetupOut {
  const TotpSetupOut({required this.qrUri, required this.secret});

  factory TotpSetupOut.fromJson(Map<String, Object?> json) =>
      _$TotpSetupOutFromJson(json);

  @JsonKey(name: 'qr_uri')
  final String qrUri;
  final String secret;

  Map<String, Object?> toJson() => _$TotpSetupOutToJson(this);
}
