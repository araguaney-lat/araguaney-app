// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_confirm_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotpConfirmOut _$TotpConfirmOutFromJson(Map<String, dynamic> json) =>
    TotpConfirmOut(
      backupCodes: (json['backup_codes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TotpConfirmOutToJson(TotpConfirmOut instance) =>
    <String, dynamic>{'backup_codes': instance.backupCodes};
