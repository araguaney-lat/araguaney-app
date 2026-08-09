// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'box_code_block_out.g.dart';

@JsonSerializable()
class BoxCodeBlockOut {
  const BoxCodeBlockOut({required this.available, required this.codes});

  factory BoxCodeBlockOut.fromJson(Map<String, Object?> json) =>
      _$BoxCodeBlockOutFromJson(json);

  final int available;
  final List<String> codes;

  Map<String, Object?> toJson() => _$BoxCodeBlockOutToJson(this);
}
