// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/campaign_create.dart';
import '../models/campaign_member_add.dart';
import '../models/campaign_member_out.dart';
import '../models/campaign_out.dart';
import '../models/campaign_update.dart';
import '../models/ok_out.dart';

part 'campaigns_api.g.dart';

@RestApi()
abstract class CampaignsApi {
  factory CampaignsApi(Dio dio, {String? baseUrl}) = _CampaignsApi;

  /// List Campaigns
  @GET('/v1/campaigns')
  Future<List<CampaignOut>> listCampaignsV1CampaignsGet({
    @Query('active_only') bool? activeOnly = false,
  });

  /// Create Campaign
  @POST('/v1/campaigns')
  Future<CampaignOut> createCampaignV1CampaignsPost({
    @Body() required CampaignCreate body,
  });

  /// List My Campaigns.
  ///
  /// Campaigns the current user belongs to. Donaciones Generales always first.
  @GET('/v1/campaigns/mine')
  Future<List<CampaignOut>> listMyCampaignsV1CampaignsMineGet();

  /// Get Campaign
  @GET('/v1/campaigns/{campaign_id}')
  Future<CampaignOut> getCampaignV1CampaignsCampaignIdGet({
    @Path('campaign_id') required String campaignId,
  });

  /// Update Campaign
  @PATCH('/v1/campaigns/{campaign_id}')
  Future<CampaignOut> updateCampaignV1CampaignsCampaignIdPatch({
    @Path('campaign_id') required String campaignId,
    @Body() required CampaignUpdate body,
  });

  /// List Members
  @GET('/v1/campaigns/{campaign_id}/members')
  Future<List<CampaignMemberOut>> listMembersV1CampaignsCampaignIdMembersGet({
    @Path('campaign_id') required String campaignId,
  });

  /// Add Member
  @POST('/v1/campaigns/{campaign_id}/members')
  Future<OkOut> addMemberV1CampaignsCampaignIdMembersPost({
    @Path('campaign_id') required String campaignId,
    @Body() required CampaignMemberAdd body,
  });

  /// Remove Member
  @DELETE('/v1/campaigns/{campaign_id}/members/{user_id}')
  Future<void> removeMemberV1CampaignsCampaignIdMembersUserIdDelete({
    @Path('campaign_id') required String campaignId,
    @Path('user_id') required String userId,
  });
}
