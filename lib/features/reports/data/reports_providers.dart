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

/// The campaign being looked at.
///
/// It lives outside the screen because the seven reports hang from it: with
/// none chosen there is nothing to ask for, and with another chosen everything
/// changes at once.
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

/// The weight gathered, and the goal if the campaign has one.
///
/// It is asked for with the centre being worked in: for a session with a centre
/// of its own it makes no difference — the server already narrows it — and for
/// a national administration it is the difference between one centre's weight
/// and the country's.
final reportWeightProvider =
    FutureProvider.family<ReportOutcome<WeightDashboardOut>, String?>(
      (ref, campaignId) => ref
          .watch(reportsRepositoryProvider)
          .weight(
            campaignId: campaignId,
            centerId: ref.watch(writeCenterIdProvider),
          ),
    );
