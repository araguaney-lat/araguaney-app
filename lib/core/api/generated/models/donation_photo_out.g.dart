// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_photo_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationPhotoOut _$DonationPhotoOutFromJson(Map<String, dynamic> json) =>
    DonationPhotoOut(
      contentType: json['content_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      id: json['id'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
    );

Map<String, dynamic> _$DonationPhotoOutToJson(DonationPhotoOut instance) =>
    <String, dynamic>{
      'content_type': instance.contentType,
      'created_at': instance.createdAt.toIso8601String(),
      'id': instance.id,
      'size_bytes': instance.sizeBytes,
    };
