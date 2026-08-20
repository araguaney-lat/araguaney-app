// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/national_dashboard_out.dart';
import '../models/public_campaign_list_item_out.dart';
import '../models/public_campaign_out.dart';
import '../models/public_needs_out.dart';
import '../models/weight_dashboard_out.dart';

part 'dashboard_api.g.dart';

@RestApi()
abstract class DashboardApi {
  factory DashboardApi(Dio dio, {String? baseUrl}) = _DashboardApi;

  /// National Dashboard.
  ///
  /// Aggregate dashboard.
  ///
  /// national_admin → all centers.
  /// coordinator/volunteer → their center only.
  @GET('/v1/dashboard/national')
  Future<NationalDashboardOut> nationalDashboardV1DashboardNationalGet();

  /// National Summary.
  ///
  /// Párrafo redactado sobre las cifras que este panel ya calcula.
  ///
  /// `null` si la capacidad está apagada o no hay inventario que resumir: el.
  /// panel muestra sus cifras igual, que es como se ve hoy.
  @GET('/v1/dashboard/national/summary')
  Future<dynamic> nationalSummaryV1DashboardNationalSummaryGet();

  /// Weight Dashboard.
  ///
  /// Weight metrics per campaign + per center.
  ///
  /// national_admin: can query any campaign_id / center_id.
  /// coordinator/volunteer: scoped to their center; campaign_id ignored outside their campaigns.
  @GET('/v1/dashboard/weight')
  Future<WeightDashboardOut> weightDashboardV1DashboardWeightGet({
    @Query('campaign_id') String? campaignId,
    @Query('center_id') String? centerId,
  });

  /// Public Campaigns.
  ///
  /// Active, non-general campaigns — safe for public listing (sitemap, event links).
  ///
  /// No PII, no operational data. Feeds sitemap.xml and internal linking on the frontend.
  @GET('/v1/public/campaigns')
  Future<List<PublicCampaignListItemOut>> publicCampaignsV1PublicCampaignsGet();

  /// Public Campaign Detail.
  ///
  /// Event landing page data: campaign context + what's needed for it.
  ///
  /// Only active, non-general campaigns are exposed — draft/inactive/general.
  /// campaigns 404 here even if the slug exists.
  @GET('/v1/public/campaigns/{slug}')
  Future<PublicCampaignOut> publicCampaignDetailV1PublicCampaignsSlugGet({
    @Path('slug') required String slug,
  });

  /// Public Needs.
  ///
  /// Public read-only snapshot: what categories have sealed stock.
  ///
  /// No PII, no center names, no auth required.
  /// Cached in Redis; Cloudflare/Vercel CDN adds another cache layer via.
  /// Cache-Control headers.
  @GET('/v1/public/needs')
  Future<PublicNeedsOut> publicNeedsV1PublicNeedsGet();
}
