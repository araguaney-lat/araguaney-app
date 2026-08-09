// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'token_in.g.dart';

@JsonSerializable()
class TokenIn {
  const TokenIn({required this.token});

  factory TokenIn.fromJson(Map<String, Object?> json) =>
      _$TokenInFromJson(json);

  final String token;

  Map<String, Object?> toJson() => _$TokenInToJson(this);
}
