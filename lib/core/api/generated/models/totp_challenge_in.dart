// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'totp_challenge_in.g.dart';

@JsonSerializable()
class TotpChallengeIn {
  const TotpChallengeIn({required this.code, required this.partialToken});

  factory TotpChallengeIn.fromJson(Map<String, Object?> json) =>
      _$TotpChallengeInFromJson(json);

  final String code;
  @JsonKey(name: 'partial_token')
  final String partialToken;

  Map<String, Object?> toJson() => _$TotpChallengeInToJson(this);
}
