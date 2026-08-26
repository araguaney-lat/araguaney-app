import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/center_application_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'center_applications_repository.dart';

final centerApplicationsRepositoryProvider =
    Provider<CenterApplicationsRepository>(
      (ref) => CenterApplicationsRepository(
        ref.watch(restClientProvider).centerApplications,
      ),
    );

/// What is waiting for a decision.
final applicationQueueProvider =
    FutureProvider<ApplicationsOutcome<List<CenterApplicationOut>>>(
      (ref) => ref.watch(centerApplicationsRepositoryProvider).queue(),
    );

/// Whether this session can review applications.
///
/// The backend accepts a national administration — narrowed to its country — or
/// a superadministration, which sees them all. From the client both look alike
/// through `center_role`, so this only avoids offering a screen that is going
/// to answer 403; who sees what is still the server's decision.
final canReviewApplicationsProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);
