// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemsIn _$ItemsInFromJson(Map<String, dynamic> json) => ItemsIn(
  items: (json['items'] as List<dynamic>)
      .map((e) => DonationItemInput.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ItemsInToJson(ItemsIn instance) => <String, dynamic>{
  'items': instance.items,
};
