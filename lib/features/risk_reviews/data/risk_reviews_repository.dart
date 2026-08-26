import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/risk_reviews_api.dart';
import '../../../core/api/generated/models/risk_review_out.dart';
import '../../../core/api/generated/models/risk_review_resolve_in.dart';

/// The two ways of closing a review.
///
/// Approving lets the capture through; rejecting stops it. The server accepts
/// nothing else, and what each one means for the inventory is its decision.
abstract final class RiskResolution {
  static const approve = 'APPROVED';
  static const reject = 'REJECTED';
}

sealed class ResolveOutcome {
  const ResolveOutcome();
}

final class ReviewResolved extends ResolveOutcome {
  const ReviewResolved(this.review);

  final RiskReviewOut review;
}

final class ResolveRefused extends ResolveOutcome {
  const ResolveRefused(this.failure);

  final ApiFailure failure;
}

/// The centre's risk reviews.
class RiskReviewsRepository {
  RiskReviewsRepository(this._reviews);

  final RiskReviewsApi _reviews;

  /// The ones still pending. The server does not return the resolved ones, so a
  /// review that is closed disappears from the list without anybody filtering
  /// it.
  Future<List<RiskReviewOut>> pending() =>
      _reviews.listRiskReviewsV1RiskReviewsGet();

  /// Closes a review.
  ///
  /// The note is optional in the contract and optional here too. Requiring it
  /// would be a client rule, and whoever resolves usually has somebody waiting
  /// in front of them; the server decides what is needed.
  Future<ResolveOutcome> resolve({
    required String reviewId,
    required String resolution,
    String? note,
  }) async {
    try {
      final review = await _reviews
          .resolveRiskReviewV1RiskReviewsReviewIdResolvePost(
            reviewId: reviewId,
            body: RiskReviewResolveIn(resolution: resolution, note: note),
          );
      return ReviewResolved(review);
    } on Object catch (error) {
      // Somebody else having resolved it from the panel while this screen was
      // open is the normal case, not an oddity: the server answers that it is
      // already resolved and that text is what gets shown.
      return ResolveRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
