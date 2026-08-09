// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'public_center_out.g.dart';

/// Centro visible para quien va a donar.
///
/// Deliberadamente sin correo ni teléfono de contacto: el formulario solo.
/// necesita saber a dónde piensa llevar la donación, y publicar datos de.
/// contacto de cada centro sería una lista de correos servida en bandeja.
@JsonSerializable()
class PublicCenterOut {
  const PublicCenterOut({
    required this.countryCode,
    required this.id,
    required this.name,
    required this.stateName,
  });

  factory PublicCenterOut.fromJson(Map<String, Object?> json) =>
      _$PublicCenterOutFromJson(json);

  @JsonKey(name: 'country_code')
  final String? countryCode;
  final String id;
  final String name;
  @JsonKey(name: 'state_name')
  final String? stateName;

  Map<String, Object?> toJson() => _$PublicCenterOutToJson(this);
}
