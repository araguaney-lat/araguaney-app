// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'unread_count_out.g.dart';

/// Mensajes privados sin leer de quien consulta. Lo pinta el badge del menú.
@JsonSerializable()
class UnreadCountOut {
  const UnreadCountOut({required this.unread});

  factory UnreadCountOut.fromJson(Map<String, Object?> json) =>
      _$UnreadCountOutFromJson(json);

  final int unread;

  Map<String, Object?> toJson() => _$UnreadCountOutToJson(this);
}
