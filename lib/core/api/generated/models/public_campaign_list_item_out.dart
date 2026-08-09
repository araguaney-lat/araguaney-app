// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'public_campaign_list_item_out.g.dart';

/// Safe for public listing: no PII, just what's needed to build a link/card.
///
/// Incluye `id` porque el formulario de donación manda la campaña elegida como.
/// intención; el UUID no es secreto y la ficha ya es pública por slug.
@JsonSerializable()
class PublicCampaignListItemOut {
  const PublicCampaignListItemOut({
    required this.destinationCountry,
    required this.id,
    required this.name,
    required this.slug,
  });

  factory PublicCampaignListItemOut.fromJson(Map<String, Object?> json) =>
      _$PublicCampaignListItemOutFromJson(json);

  @JsonKey(name: 'destination_country')
  final String? destinationCountry;
  final String id;
  final String name;
  final String slug;

  Map<String, Object?> toJson() => _$PublicCampaignListItemOutToJson(this);
}
