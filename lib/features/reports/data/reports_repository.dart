import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/export_job.dart';
import '../../../core/api/generated/clients/dashboard_api.dart';
import '../../../core/api/generated/clients/exports_api.dart';
import '../../../core/api/generated/clients/reports_api.dart';
import '../../../core/api/generated/models/activity_point.dart';
import '../../../core/api/generated/models/category_breakdown.dart';
import '../../../core/api/generated/models/country_point.dart';
import '../../../core/api/generated/models/report_summary.dart';
import '../../../core/api/generated/models/shrinkage_summary.dart';
import '../../../core/api/generated/models/weight_dashboard_out.dart';

sealed class ReportOutcome<T> {
  const ReportOutcome();
}

final class ReportRead<T> extends ReportOutcome<T> {
  const ReportRead(this.value);

  final T value;
}

final class ReportRefused<T> extends ReportOutcome<T> {
  const ReportRefused(this.failure);

  final ApiFailure failure;

  /// Whether the refusal is «you do not take part in this campaign». The seven
  /// reports go through `require_campaign_access`, so it is the expected answer
  /// and not a failure: the screen says so without alarm.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// A campaign's reports.
///
/// **They all hang from a campaign and none is cached.** A report is a question
/// about now: storing it to answer without signal would be answering today's
/// question with yesterday's number.
///
/// None of them takes a date range from here. The server has its own default,
/// and a phone screen that starts by asking for two dates is a screen nobody
/// opens twice. The shrinkage also takes no range on purpose: a shipment is
/// received weeks after it leaves.
class ReportsRepository {
  ReportsRepository({
    required ReportsApi reports,
    required DashboardApi dashboard,
    required ExportsApi exports,
  }) : _reportsApi = reports,
       _dashboardApi = dashboard,
       _exportsApi = exports;

  final ReportsApi _reportsApi;
  final DashboardApi _dashboardApi;
  final ExportsApi _exportsApi;

  Future<ReportOutcome<ReportSummary>> summary(String campaignId) => _guard(
    () => _reportsApi.getSummaryV1ReportsCampaignCampaignIdSummaryGet(
      campaignId: campaignId,
    ),
  );

  Future<ReportOutcome<ShrinkageSummary>> shrinkage(String campaignId) =>
      _guard(
        () => _reportsApi.getShrinkageV1ReportsCampaignCampaignIdShrinkageGet(
          campaignId: campaignId,
        ),
      );

  Future<ReportOutcome<List<CategoryBreakdown>>> byCategory(
    String campaignId,
  ) => _guard(
    () => _reportsApi.getByCategoryV1ReportsCampaignCampaignIdByCategoryGet(
      campaignId: campaignId,
    ),
  );

  Future<ReportOutcome<List<CountryPoint>>> countries(String campaignId) =>
      _guard(
        () => _reportsApi.getCountriesV1ReportsCampaignCampaignIdCountriesGet(
          campaignId: campaignId,
        ),
      );

  Future<ReportOutcome<List<ActivityPoint>>> activity(String campaignId) =>
      _guard(
        () => _reportsApi.getActivityV1ReportsCampaignCampaignIdActivityGet(
          campaignId: campaignId,
        ),
      );

  /// How much what was gathered weighs, and against which goal.
  ///
  /// It belongs to the weight panel and not to the reports: it only requires a
  /// centre role, so it is seen by somebody who takes part in no particular
  /// campaign.
  Future<ReportOutcome<WeightDashboardOut>> weight({
    String? campaignId,
    String? centerId,
  }) => _guard(
    () => _dashboardApi.weightDashboardV1DashboardWeightGet(
      campaignId: campaignId,
      centerId: centerId,
    ),
  );

  /// Asks for the CSV and waits for the server to assemble it.
  ///
  /// The file is handed to the system's viewer. Drawing a spreadsheet is not
  /// this application's job and is not going to be.
  Future<DocumentOutcome> exportCsv(
    String campaignId, {
    Future<void> Function(Duration) wait = Future.delayed,
  }) => awaitDocument(
    start: () => _reportsApi.exportCsvV1ReportsCampaignCampaignIdExportCsvPost(
      campaignId: campaignId,
    ),
    exports: _exportsApi,
    wait: wait,
  );

  Future<ReportOutcome<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return ReportRead(await call());
    } on Object catch (error) {
      return ReportRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
