// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_item_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationItemOut _$DonationItemOutFromJson(Map<String, dynamic> json) =>
    DonationItemOut(
      addedBy: json['added_by'] as String,
      freeText: json['free_text'] as String?,
      id: json['id'] as String,
      productTypeId: json['product_type_id'] as String?,
      quantity: (json['quantity'] as num).toInt(),
      receptionStatus: json['reception_status'] as String?,
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$DonationItemOutToJson(DonationItemOut instance) =>
    <String, dynamic>{
      'added_by': instance.addedBy,
      'free_text': instance.freeText,
      'id': instance.id,
      'product_type_id': instance.productTypeId,
      'quantity': instance.quantity,
      'reception_status': instance.receptionStatus,
      'unit': instance.unit,
    };
