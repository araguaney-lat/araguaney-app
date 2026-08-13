// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_pallet_box_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrPalletBoxRow _$QrPalletBoxRowFromJson(Map<String, dynamic> json) =>
    QrPalletBoxRow(
      category: json['category'] as String,
      displayName: json['display_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unit: json['unit'] as String,
      weightKg: json['weight_kg'] as String?,
    );

Map<String, dynamic> _$QrPalletBoxRowToJson(QrPalletBoxRow instance) =>
    <String, dynamic>{
      'category': instance.category,
      'display_name': instance.displayName,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'weight_kg': instance.weightKg,
    };
