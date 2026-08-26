import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'campaigns_repository.dart';

final campaignsRepositoryProvider = Provider<CampaignsRepository>(
  (ref) => CampaignsRepository(ref.watch(restClientProvider).campaigns),
);

/// Si esta sesión puede mirar las campañas de la plataforma.
///
/// `require_coordinator` en la lista y en la ficha. Quien es voluntariado sigue
/// eligiendo campaña al capturar —eso va por `mine`, que solo exige rol de
/// centro— pero no tiene dónde abrirla, así que tampoco se le ofrece.
final canBrowseCampaignsProvider = Provider<bool>(
  (ref) => ref.watch(isCenterCoordinatorProvider),
);

/// Si además puede crearlas y editarlas. Es otro permiso y otro rol.
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
