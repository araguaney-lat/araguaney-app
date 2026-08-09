// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'rx_norm_suggestion.g.dart';

@JsonSerializable()
class RxNormSuggestion {
  const RxNormSuggestion({required this.name, required this.rxcui});

  factory RxNormSuggestion.fromJson(Map<String, Object?> json) =>
      _$RxNormSuggestionFromJson(json);

  final String name;
  final String rxcui;

  Map<String, Object?> toJson() => _$RxNormSuggestionToJson(this);
}
