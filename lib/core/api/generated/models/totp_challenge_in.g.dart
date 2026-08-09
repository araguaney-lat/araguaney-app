// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'totp_challenge_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotpChallengeIn _$TotpChallengeInFromJson(Map<String, dynamic> json) =>
    TotpChallengeIn(
      code: json['code'] as String,
      partialToken: json['partial_token'] as String,
    );

Map<String, dynamic> _$TotpChallengeInToJson(TotpChallengeIn instance) =>
    <String, dynamic>{
      'code': instance.code,
      'partial_token': instance.partialToken,
    };
