// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donation_item_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DonationItemInput _$DonationItemInputFromJson(Map<String, dynamic> json) =>
    DonationItemInput(
      quantity: (json['quantity'] as num).toInt(),
      unit: json['unit'] as String,
      freeText: json['free_text'] as String?,
      productTypeId: json['product_type_id'] as String?,
    );

Map<String, dynamic> _$DonationItemInputToJson(DonationItemInput instance) =>
    <String, dynamic>{
      'free_text': instance.freeText,
      'product_type_id': instance.productTypeId,
      'quantity': instance.quantity,
      'unit': instance.unit,
    };
