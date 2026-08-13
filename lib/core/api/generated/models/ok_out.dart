// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ok_out.g.dart';

/// Acuse de una operación que no devuelve nada que leer.
///
/// Lo usan el alta de una persona en una campaña y las dos escrituras públicas.
/// de donación. Vale aquí la misma nota que en [MessageOut]: quien las llama.
/// descarta el cuerpo, así que la respuesta honesta sería un `204`, y cambiarlo.
/// dentro de `/v1` rompería a un cliente instalado. Material para una `/v2`.
@JsonSerializable()
class OkOut {
  const OkOut({required this.ok});

  factory OkOut.fromJson(Map<String, Object?> json) => _$OkOutFromJson(json);

  final bool ok;

  Map<String, Object?> toJson() => _$OkOutToJson(this);
}
