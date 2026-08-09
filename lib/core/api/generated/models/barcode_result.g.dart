// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BarcodeResult _$BarcodeResultFromJson(Map<String, dynamic> json) =>
    BarcodeResult(
      source: BarcodeResultSource.fromJson(json['source'] as String),
      prefill: json['prefill'] == null
          ? null
          : BarcodePrefill.fromJson(json['prefill'] as Map<String, dynamic>),
      productType: json['product_type'] == null
          ? null
          : ProductTypeOut.fromJson(
              json['product_type'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BarcodeResultToJson(BarcodeResult instance) =>
    <String, dynamic>{
      'prefill': instance.prefill,
      'product_type': instance.productType,
      'source': instance.source,
    };
