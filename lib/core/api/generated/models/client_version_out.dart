// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'client_version_out.g.dart';

/// Versiones del cliente nativo que el backend soporta.
///
/// `min_supported`: por debajo de esto, la app debe bloquear y pedir.
/// actualización — el contrato ya no le garantiza compatibilidad.
/// `latest`: la última publicada; la app puede sugerir actualizar sin bloquear.
@JsonSerializable()
class ClientVersionOut {
  const ClientVersionOut({required this.latest, required this.minSupported});

  factory ClientVersionOut.fromJson(Map<String, Object?> json) =>
      _$ClientVersionOutFromJson(json);

  final String latest;
  @JsonKey(name: 'min_supported')
  final String minSupported;

  Map<String, Object?> toJson() => _$ClientVersionOutToJson(this);
}
