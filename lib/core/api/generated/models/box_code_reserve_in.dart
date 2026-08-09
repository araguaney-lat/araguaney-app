// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'box_code_reserve_in.g.dart';

/// Petición de un bloque de códigos pre-asignados (Fase 25).
@JsonSerializable()
class BoxCodeReserveIn {
  const BoxCodeReserveIn({required this.count, this.centerId});

  factory BoxCodeReserveIn.fromJson(Map<String, Object?> json) =>
      _$BoxCodeReserveInFromJson(json);

  @JsonKey(name: 'center_id')
  final String? centerId;
  final int count;

  Map<String, Object?> toJson() => _$BoxCodeReserveInToJson(this);
}
