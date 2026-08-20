import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/national_dashboard_out.dart';
import 'center_dashboard_repository.dart';

final centerDashboardRepositoryProvider = Provider<CenterDashboardRepository>(
  (ref) => CenterDashboardRepository(ref.watch(restClientProvider).dashboard),
);

final centerAggregatesProvider = FutureProvider<NationalDashboardOut>(
  (ref) => ref.watch(centerDashboardRepositoryProvider).aggregates(),
);
