// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_campaign_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicCampaignOut _$PublicCampaignOutFromJson(Map<String, dynamic> json) =>
    PublicCampaignOut(
      byCategory: (json['by_category'] as List<dynamic>)
          .map((e) => CategoryStockOut.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String?,
      destinationCountry: json['destination_country'] as String?,
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      name: json['name'] as String,
      slug: json['slug'] as String,
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
    );

Map<String, dynamic> _$PublicCampaignOutToJson(PublicCampaignOut instance) =>
    <String, dynamic>{
      'by_category': instance.byCategory,
      'description': instance.description,
      'destination_country': instance.destinationCountry,
      'end_date': instance.endDate?.toIso8601String(),
      'name': instance.name,
      'slug': instance.slug,
      'start_date': instance.startDate?.toIso8601String(),
    };
