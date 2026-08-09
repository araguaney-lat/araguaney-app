// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_campaign_list_item_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicCampaignListItemOut _$PublicCampaignListItemOutFromJson(
  Map<String, dynamic> json,
) => PublicCampaignListItemOut(
  destinationCountry: json['destination_country'] as String?,
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
);

Map<String, dynamic> _$PublicCampaignListItemOutToJson(
  PublicCampaignListItemOut instance,
) => <String, dynamic>{
  'destination_country': instance.destinationCountry,
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
};
