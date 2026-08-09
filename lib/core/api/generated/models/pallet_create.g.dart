// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pallet_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PalletCreate _$PalletCreateFromJson(Map<String, dynamic> json) => PalletCreate(
  centerId: json['center_id'] as String?,
  notes: json['notes'] as String?,
  tareWeightKg: json['tare_weight_kg'],
);

Map<String, dynamic> _$PalletCreateToJson(PalletCreate instance) =>
    <String, dynamic>{
      'center_id': instance.centerId,
      'notes': instance.notes,
      'tare_weight_kg': instance.tareWeightKg,
    };
