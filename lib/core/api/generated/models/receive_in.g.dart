// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receive_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiveIn _$ReceiveInFromJson(Map<String, dynamic> json) => ReceiveIn(
  centerId: json['center_id'] as String?,
  extras: (json['extras'] as List<dynamic>?)
      ?.map((e) => DonationItemInput.fromJson(e as Map<String, dynamic>))
      .toList(),
  results: (json['results'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$ReceiveInToJson(ReceiveIn instance) => <String, dynamic>{
  'center_id': instance.centerId,
  'extras': instance.extras,
  'results': instance.results,
};
