// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_pallet_weight_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceptionPalletWeightIn _$ReceptionPalletWeightInFromJson(
  Map<String, dynamic> json,
) => ReceptionPalletWeightIn(
  grossWeightKg: json['gross_weight_kg'],
  palletId: json['pallet_id'] as String,
);

Map<String, dynamic> _$ReceptionPalletWeightInToJson(
  ReceptionPalletWeightIn instance,
) => <String, dynamic>{
  'gross_weight_kg': instance.grossWeightKg,
  'pallet_id': instance.palletId,
};
