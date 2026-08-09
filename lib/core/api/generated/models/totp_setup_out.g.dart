// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_setup_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotpSetupOut _$TotpSetupOutFromJson(Map<String, dynamic> json) => TotpSetupOut(
  qrUri: json['qr_uri'] as String,
  secret: json['secret'] as String,
);

Map<String, dynamic> _$TotpSetupOutToJson(TotpSetupOut instance) =>
    <String, dynamic>{'qr_uri': instance.qrUri, 'secret': instance.secret};
