import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/category_breakdown.dart';
import 'reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(restClientProvider).reports),
);

final categoryTotalsProvider =
    FutureProvider.family<List<CategoryBreakdown>, String>(
      (ref, campaignId) =>
          ref.watch(reportsRepositoryProvider).byCategory(campaignId),
    );
