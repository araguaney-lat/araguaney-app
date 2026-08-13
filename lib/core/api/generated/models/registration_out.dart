// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'registration_out.g.dart';

/// Resultado de darse de alta.
///
/// Tiene dos formas según la configuración de verificación por correo: con.
/// sesión inmediata, o solo el aviso de que hay un correo en camino. Por eso el.
/// token es opcional, y no porque a veces falte por descuido.
@JsonSerializable()
class RegistrationOut {
  const RegistrationOut({required this.message, this.accessToken});

  factory RegistrationOut.fromJson(Map<String, Object?> json) =>
      _$RegistrationOutFromJson(json);

  @JsonKey(name: 'access_token')
  final String? accessToken;
  final String message;

  Map<String, Object?> toJson() => _$RegistrationOutToJson(this);
}
