// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'donation_photo_out.g.dart';

/// Lo que el cliente necesita para pintar la galería.
///
/// Sin `storage_key`: la llave del almacenamiento es un detalle del servidor y.
/// publicarla invitaría a construir rutas a mano.
@JsonSerializable()
class DonationPhotoOut {
  const DonationPhotoOut({
    required this.contentType,
    required this.createdAt,
    required this.id,
    required this.sizeBytes,
  });

  factory DonationPhotoOut.fromJson(Map<String, Object?> json) =>
      _$DonationPhotoOutFromJson(json);

  @JsonKey(name: 'content_type')
  final String contentType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  Map<String, Object?> toJson() => _$DonationPhotoOutToJson(this);
}
