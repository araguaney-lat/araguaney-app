import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/activity_point.dart';
import '../../../core/api/generated/models/category_breakdown.dart';
import '../../../core/api/generated/models/country_point.dart';
import '../../../core/api/generated/models/report_summary.dart';
import '../../../core/api/generated/models/shrinkage_summary.dart';
import '../../../core/api/generated/models/weight_dashboard_out.dart';
import '../../../core/center/center_providers.dart';
import 'reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return ReportsRepository(
    reports: client.reports,
    dashboard: client.dashboard,
    exports: client.exports,
  );
});

/// La campaña que se está mirando.
///
/// Vive fuera de la pantalla porque los siete informes cuelgan de ella: sin una
/// elegida no hay nada que pedir, y con otra elegida cambia todo a la vez.
final selectedCampaignProvider = StateProvider<String?>((ref) => null);

final reportSummaryProvider =
    FutureProvider.family<ReportOutcome<ReportSummary>, String>(
      (ref, campaignId) =>
          ref.watch(reportsRepositoryProvider).summary(campaignId),
    );

final reportShrinkageProvider =
    FutureProvider.family<ReportOutcome<ShrinkageSummary>, String>(
      (ref, campaignId) =>
          ref.watch(reportsRepositoryProvider).shrinkage(campaignId),
    );

final reportByCategoryProvider =
    FutureProvider.family<ReportOutcome<List<CategoryBreakdown>>, String>(
      (ref, campaignId) =>
          ref.watch(reportsRepositoryProvider).byCategory(campaignId),
    );

final reportCountriesProvider =
    FutureProvider.family<ReportOutcome<List<CountryPoint>>, String>(
      (ref, campaignId) =>
          ref.watch(reportsRepositoryProvider).countries(campaignId),
    );

final reportActivityProvider =
    FutureProvider.family<ReportOutcome<List<ActivityPoint>>, String>(
      (ref, campaignId) =>
          ref.watch(reportsRepositoryProvider).activity(campaignId),
    );

/// El peso reunido, y la meta si la campaña tiene una.
///
/// Se pide con el centro en el que se está trabajando: para una sesión con
/// centro propio da igual —el servidor ya lo acota— y para una administración
/// nacional es la diferencia entre el peso de un centro y el del país.
final reportWeightProvider =
    FutureProvider.family<ReportOutcome<WeightDashboardOut>, String?>(
      (ref, campaignId) => ref
          .watch(reportsRepositoryProvider)
          .weight(
            campaignId: campaignId,
            centerId: ref.watch(writeCenterIdProvider),
          ),
    );
