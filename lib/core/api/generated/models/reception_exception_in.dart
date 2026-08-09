// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reception_exception_in.g.dart';

/// Una caja que **no** llegó bien.
///
/// Solo viajan las excepciones: lo que no aparece en la lista se da por.
/// recibido. La merma es la minoría y el formulario optimiza para el caso.
/// normal.
@JsonSerializable()
class ReceptionExceptionIn {
  const ReceptionExceptionIn({
    required this.boxId,
    required this.outcome,
    this.note,
  });

  factory ReceptionExceptionIn.fromJson(Map<String, Object?> json) =>
      _$ReceptionExceptionInFromJson(json);

  @JsonKey(name: 'box_id')
  final String boxId;
  final String? note;
  final String outcome;

  Map<String, Object?> toJson() => _$ReceptionExceptionInToJson(this);
}
