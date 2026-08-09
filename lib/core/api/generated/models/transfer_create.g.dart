// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferCreate _$TransferCreateFromJson(Map<String, dynamic> json) =>
    TransferCreate(
      boxIds: (json['box_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      fromCenterId: json['from_center_id'] as String,
      toCenterId: json['to_center_id'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$TransferCreateToJson(TransferCreate instance) =>
    <String, dynamic>{
      'box_ids': instance.boxIds,
      'from_center_id': instance.fromCenterId,
      'notes': instance.notes,
      'to_center_id': instance.toCenterId,
    };
