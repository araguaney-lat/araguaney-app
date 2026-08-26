import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/campaign_member_out.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/center/center_providers.dart';
import 'team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return TeamRepository(campaigns: client.campaigns, users: client.users);
});

/// The own centre's team.
///
/// «Own» now includes the chosen one: a national administrator belongs to no
/// centre, and used to get a directory of nobody. With a working centre there
/// is an answer, and the backend already allows it — `list_center_users` lets a
/// national administrator read any centre's team.
final centerUsersProvider = FutureProvider<List<UserOut>>((ref) {
  final centerId = ref.watch(actingCenterIdProvider);
  if (centerId == null) return Future.value(const []);
  return ref.watch(teamRepositoryProvider).centerUsers(centerId);
});

final campaignMembersProvider =
    FutureProvider.family<List<CampaignMemberOut>, String>(
      (ref, campaignId) =>
          ref.watch(teamRepositoryProvider).members(campaignId),
    );
