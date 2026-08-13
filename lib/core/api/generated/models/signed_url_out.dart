// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'signed_url_out.g.dart';

/// URL temporal para descargar un archivo privado.
///
/// Es de un solo uso conceptual: caduca, no se cachea y no se guarda. Por eso.
/// los endpoints que la entregan responden con `Cache-Control` de no.
/// almacenamiento.
@JsonSerializable()
class SignedUrlOut {
  const SignedUrlOut({required this.url});

  factory SignedUrlOut.fromJson(Map<String, Object?> json) =>
      _$SignedUrlOutFromJson(json);

  final String url;

  Map<String, Object?> toJson() => _$SignedUrlOutToJson(this);
}
