// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'message_out.g.dart';

/// Confirmación de una acción que no devuelve datos.
///
/// Siete endpoints responden así: verificar correo, reenviar verificación,.
/// recuperar y restablecer contraseña, desactivar el segundo factor y los dos.
/// reenvíos de invitación. Ninguno de sus consumidores lee esta clave; miran el.
/// estado HTTP y siguen.
///
/// Que el cuerpo no aporte nada sugiere que la respuesta honesta sería un `204`.
/// sin cuerpo. No se hace aquí porque cambiar `200` con cuerpo por `204` es un.
/// cambio incompatible de contrato, y dentro de `/v1` los cambios son solo.
/// aditivos: un cliente instalado que espere un cuerpo se rompería. Queda.
/// anotado para una `/v2`.
@JsonSerializable()
class MessageOut {
  const MessageOut({required this.message});

  factory MessageOut.fromJson(Map<String, Object?> json) =>
      _$MessageOutFromJson(json);

  final String message;

  Map<String, Object?> toJson() => _$MessageOutToJson(this);
}
