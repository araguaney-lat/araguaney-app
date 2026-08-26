import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/intake_out.dart';
import '../../catalog/data/catalog_providers.dart';
import '../../intake/data/intake_providers.dart';
import '../../pallets/data/pallets_providers.dart';
import '../../risk_reviews/data/risk_reviews_providers.dart';

/// Reviews waiting for a decision.
///
/// The server returns the centre's; only the ones still pending are counted
/// here, because a resolved one asks nothing of anybody.
final pendingReviewCountProvider = Provider<int>((ref) {
  final reviews = ref.watch(riskReviewsProvider).valueOrNull ?? const [];
  return reviews.where((review) => review.status == 'PENDING').length;
});

/// Open pallets: the ones that still take boxes.
final openPalletCountProvider = Provider<int>((ref) {
  final pallets = ref.watch(palletsProvider).valueOrNull ?? const [];
  return pallets.where((pallet) => pallet.closedAt == null).length;
});

/// Captures registered at the centre today.
///
/// It filters by the local date and not the server's: whoever asks «how many so
/// far today» is thinking of their shift, which starts when the sun comes up
/// where they are.
final todaysIntakeCountProvider = Provider<int>((ref) {
  final intakes = ref.watch(intakesProvider).valueOrNull ?? const <IntakeOut>[];
  final now = DateTime.now();
  return intakes.where((intake) {
    final at = intake.createdAt.toLocal();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }).length;
});

/// How much work can be done without signal right now.
///
/// The two figures that decide whether a shift without a connection is
/// possible: the catalogue that can be consulted and the reserved box codes
/// that can be spent. Zero codes with zero signal means being unable to seal
/// anything.
final offlineReadinessProvider = Provider<({int products, int codes})>((ref) {
  // With no category: the whole catalogue, which is what was downloaded.
  final products =
      ref.watch(productTypesProvider(null)).valueOrNull?.length ?? 0;
  final codes = ref.watch(availableBoxCodesProvider).valueOrNull ?? 0;
  return (products: products, codes: codes);
});
