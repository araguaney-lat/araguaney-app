import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/campaign_member_out.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return TeamRepository(campaigns: client.campaigns, users: client.users);
});

/// El equipo del propio centro.
///
/// Sin centro no hay directorio: una administración nacional no pertenece a
/// uno, y elegir cuál mirar es trabajo de escritorio.
final centerUsersProvider = FutureProvider<List<UserOut>>((ref) {
  final centerId = ref.watch(myCenterIdProvider);
  if (centerId == null) return Future.value(const []);
  return ref.watch(teamRepositoryProvider).centerUsers(centerId);
});

final campaignMembersProvider =
    FutureProvider.family<List<CampaignMemberOut>, String>(
      (ref, campaignId) =>
          ref.watch(teamRepositoryProvider).members(campaignId),
    );
