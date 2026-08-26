import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/risk_review_out.dart';
import 'risk_reviews_repository.dart';

final riskReviewsRepositoryProvider = Provider<RiskReviewsRepository>(
  (ref) => RiskReviewsRepository(ref.watch(restClientProvider).riskReviews),
);

/// Risk reviews open over the centre's captures.
///
/// They are looked up online: a review is a conversation in progress with
/// coordination, and showing an old copy of something somebody else may have
/// resolved ten minutes ago would be worse than asking for a connection.
final riskReviewsProvider = FutureProvider<List<RiskReviewOut>>(
  (ref) => ref.watch(riskReviewsRepositoryProvider).pending(),
);
