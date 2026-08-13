import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/clients/risk_reviews_api.dart';
import '../../../core/api/generated/models/risk_review_out.dart';
import '../../../core/api/generated/models/risk_review_resolve_in.dart';

/// Las dos formas de cerrar una revisión.
///
/// Aprobar deja pasar la captura; rechazar la detiene. El servidor no acepta
/// nada más, y qué significa cada una para el inventario lo decide él.
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

/// Revisiones de riesgo del centro.
class RiskReviewsRepository {
  RiskReviewsRepository(this._reviews);

  final RiskReviewsApi _reviews;

  /// Las que siguen pendientes. El servidor no devuelve las resueltas, así que
  /// una revisión que se cierra desaparece de la lista sin que nadie la filtre.
  Future<List<RiskReviewOut>> pending() =>
      _reviews.listRiskReviewsV1RiskReviewsGet();

  /// Cierra una revisión.
  ///
  /// La nota es opcional en el contrato y también aquí. Exigirla sería una
  /// regla del cliente, y quien resuelve suele tener a alguien esperando
  /// enfrente; el servidor decide qué hace falta.
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
      // Que otra persona la haya resuelto desde el panel mientras esta pantalla
      // estaba abierta es el caso normal, no una rareza: el servidor responde
      // que ya está resuelta y ese texto es el que se muestra.
      return ResolveRefused(ApiErrorMapper.fromAny(error));
    }
  }
}
