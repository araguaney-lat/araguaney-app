// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_pallet_weight_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceptionPalletWeightOut _$ReceptionPalletWeightOutFromJson(
  Map<String, dynamic> json,
) => ReceptionPalletWeightOut(
  grossWeightKg: json['gross_weight_kg'] as String,
  palletId: json['pallet_id'] as String,
);

Map<String, dynamic> _$ReceptionPalletWeightOutToJson(
  ReceptionPalletWeightOut instance,
) => <String, dynamic>{
  'gross_weight_kg': instance.grossWeightKg,
  'pallet_id': instance.palletId,
};
