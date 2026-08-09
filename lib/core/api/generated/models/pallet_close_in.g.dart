// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pallet_close_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PalletCloseIn _$PalletCloseInFromJson(Map<String, dynamic> json) =>
    PalletCloseIn(
      grossWeightKg: json['gross_weight_kg'],
      heightCm: (json['height_cm'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PalletCloseInToJson(PalletCloseIn instance) =>
    <String, dynamic>{
      'gross_weight_kg': instance.grossWeightKg,
      'height_cm': instance.heightCm,
    };
