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

  /// Si el rechazo es «no participas en esta campaña». Los siete informes van
  /// por `require_campaign_access`, así que es la respuesta esperable y no un
  /// fallo: la pantalla lo dice sin alarmar.
  bool get isForbidden => failure is ForbiddenFailure;
}

/// Los informes de una campaña.
///
/// **Todos cuelgan de una campaña y ninguno se cachea.** Un informe es una
/// pregunta sobre ahora: guardarlo para responder sin señal sería contestar con
/// el número de ayer a quien pregunta por el de hoy.
///
/// Ninguno recibe rango de fechas desde aquí. El servidor tiene el suyo por
/// defecto, y una pantalla de teléfono que empieza pidiendo dos fechas es una
/// pantalla que nadie abre dos veces. La merma además no admite rango a
/// propósito: un envío se recibe semanas después de salir.
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

  /// Cuánto pesa lo reunido, y contra qué meta.
  ///
  /// Es del panel de peso y no de los informes: solo exige rol de centro, así
  /// que lo ve quien no participa en ninguna campaña concreta.
  Future<ReportOutcome<WeightDashboardOut>> weight({
    String? campaignId,
    String? centerId,
  }) => _guard(
    () => _dashboardApi.weightDashboardV1DashboardWeightGet(
      campaignId: campaignId,
      centerId: centerId,
    ),
  );

  /// Pide el CSV y espera a que el servidor lo arme.
  ///
  /// El archivo se le entrega al visor del sistema. Dibujar una hoja de cálculo
  /// no es trabajo de esta aplicación y no va a serlo.
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
