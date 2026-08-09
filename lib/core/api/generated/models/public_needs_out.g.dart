// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_needs_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicNeedsOut _$PublicNeedsOutFromJson(Map<String, dynamic> json) =>
    PublicNeedsOut(
      byCategory: (json['by_category'] as List<dynamic>)
          .map((e) => CategoryStockOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublicNeedsOutToJson(PublicNeedsOut instance) =>
    <String, dynamic>{'by_category': instance.byCategory};
