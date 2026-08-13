// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_token_register_platform.dart';

part 'device_token_register.g.dart';

/// Alta de un destino de aviso.
///
/// No lleva `user_id`: el dueño sale de la sesión. Aceptarlo del cuerpo dejaría.
/// que cualquiera con sesión registrara un token a nombre de otra persona y.
/// recibiera sus avisos.
@JsonSerializable()
class DeviceTokenRegister {
  const DeviceTokenRegister({
    required this.platform,
    required this.token,
    this.appVersion,
  });

  factory DeviceTokenRegister.fromJson(Map<String, Object?> json) =>
      _$DeviceTokenRegisterFromJson(json);

  @JsonKey(name: 'app_version')
  final String? appVersion;
  final DeviceTokenRegisterPlatform platform;
  final String token;

  Map<String, Object?> toJson() => _$DeviceTokenRegisterToJson(this);
}
