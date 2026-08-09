// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/activity_point.dart';
import '../models/category_breakdown.dart';
import '../models/center_breakdown.dart';
import '../models/country_point.dart';
import '../models/export_job_out.dart';
import '../models/report_summary.dart';
import '../models/shrinkage_summary.dart';

part 'reports_api.g.dart';

@RestApi()
abstract class ReportsApi {
  factory ReportsApi(Dio dio, {String? baseUrl}) = _ReportsApi;

  /// Get Activity
  @GET('/v1/reports/campaign/{campaign_id}/activity')
  Future<List<ActivityPoint>>
  getActivityV1ReportsCampaignCampaignIdActivityGet({
    @Path('campaign_id') required String campaignId,
    @Query('start') DateTime? start,
    @Query('end') DateTime? end,
  });

  /// Get By Category
  @GET('/v1/reports/campaign/{campaign_id}/by-category')
  Future<List<CategoryBreakdown>>
  getByCategoryV1ReportsCampaignCampaignIdByCategoryGet({
    @Path('campaign_id') required String campaignId,
    @Query('start') DateTime? start,
    @Query('end') DateTime? end,
  });

  /// Get By Center
  @GET('/v1/reports/campaign/{campaign_id}/by-center')
  Future<List<CenterBreakdown>>
  getByCenterV1ReportsCampaignCampaignIdByCenterGet({
    @Path('campaign_id') required String campaignId,
    @Query('start') DateTime? start,
    @Query('end') DateTime? end,
  });

  /// Get Countries
  @GET('/v1/reports/campaign/{campaign_id}/countries')
  Future<List<CountryPoint>>
  getCountriesV1ReportsCampaignCampaignIdCountriesGet({
    @Path('campaign_id') required String campaignId,
    @Query('start') DateTime? start,
    @Query('end') DateTime? end,
  });

  /// Export Csv.
  ///
  /// Queue the campaign CSV export generation (rate-limited: 10/min). Poll GET /v1/exports/{id}.
  @POST('/v1/reports/campaign/{campaign_id}/export.csv')
  Future<ExportJobOut> exportCsvV1ReportsCampaignCampaignIdExportCsvPost({
    @Path('campaign_id') required String campaignId,
    @Query('start') DateTime? start,
    @Query('end') DateTime? end,
  });

  /// Get Shrinkage.
  ///
  /// Merma de la campaña. Sin rango de fechas: un envío se recibe semanas.
  /// después de despacharse, y la ventana del resto del reporte lo dejaría fuera.
  @GET('/v1/reports/campaign/{campaign_id}/shrinkage')
  Future<ShrinkageSummary> getShrinkageV1ReportsCampaignCampaignIdShrinkageGet({
    @Path('campaign_id') required String campaignId,
  });

  /// Get Summary
  @GET('/v1/reports/campaign/{campaign_id}/summary')
  Future<ReportSummary> getSummaryV1ReportsCampaignCampaignIdSummaryGet({
    @Path('campaign_id') required String campaignId,
    @Query('start') DateTime? start,
    @Query('end') DateTime? end,
  });
}
