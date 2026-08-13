// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device_token_unregister.g.dart';

/// Baja de un destino.
///
/// La aplicación la llama al cerrar sesión. En un centro el teléfono se.
/// comparte, así que sin esta llamada quien use el aparato después recibiría.
/// los avisos de la persona anterior.
@JsonSerializable()
class DeviceTokenUnregister {
  const DeviceTokenUnregister({required this.token});

  factory DeviceTokenUnregister.fromJson(Map<String, Object?> json) =>
      _$DeviceTokenUnregisterFromJson(json);

  final String token;

  Map<String, Object?> toJson() => _$DeviceTokenUnregisterToJson(this);
}
