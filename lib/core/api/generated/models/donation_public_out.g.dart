// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_public_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationPublicOut _$DonationPublicOutFromJson(Map<String, dynamic> json) =>
    DonationPublicOut(
      code: json['code'] as String,
      status: json['status'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => DonationItemOut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$DonationPublicOutToJson(DonationPublicOut instance) =>
    <String, dynamic>{
      'code': instance.code,
      'items': instance.items,
      'status': instance.status,
    };
