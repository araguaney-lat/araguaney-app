import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'campaigns_repository.dart';

final campaignsRepositoryProvider = Provider<CampaignsRepository>(
  (ref) => CampaignsRepository(ref.watch(restClientProvider).campaigns),
);

/// Whether this session can look at the platform's campaigns.
///
/// `require_coordinator` on the list and on the record. Whoever volunteers goes
/// on choosing a campaign while capturing — that goes through `mine`, which
/// only requires a centre role — but has nowhere to open it, so it is not
/// offered either.
final canBrowseCampaignsProvider = Provider<bool>(
  (ref) => ref.watch(isCenterCoordinatorProvider),
);

/// Whether it can also create and edit them. It is another permission and
/// another role.
final canManageCampaignsProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);

final campaignsProvider = FutureProvider<CampaignOutcome<List<CampaignOut>>>(
  (ref) => ref.watch(campaignsRepositoryProvider).list(),
);

final campaignRecordProvider =
    FutureProvider.family<CampaignOutcome<CampaignOut>, String>(
      (ref, campaignId) =>
          ref.watch(campaignsRepositoryProvider).byId(campaignId),
    );
