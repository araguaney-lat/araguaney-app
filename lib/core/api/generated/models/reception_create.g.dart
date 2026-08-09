// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reception_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceptionCreate _$ReceptionCreateFromJson(Map<String, dynamic> json) =>
    ReceptionCreate(
      exceptions:
          (json['exceptions'] as List<dynamic>?)
              ?.map(
                (e) => ReceptionExceptionIn.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      palletWeights:
          (json['pallet_weights'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ReceptionPalletWeightIn.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      consigneeName: json['consignee_name'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ReceptionCreateToJson(ReceptionCreate instance) =>
    <String, dynamic>{
      'consignee_name': instance.consigneeName,
      'exceptions': instance.exceptions,
      'notes': instance.notes,
      'pallet_weights': instance.palletWeights,
    };
