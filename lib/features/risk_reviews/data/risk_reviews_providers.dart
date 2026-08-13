import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/risk_review_out.dart';

/// Revisiones de riesgo abiertas sobre capturas del centro.
///
/// Se consultan en línea: una revisión es una conversación en curso con la
/// coordinación, y mostrar una copia vieja de algo que otra persona puede haber
/// resuelto hace diez minutos sería peor que pedir conexión.
final riskReviewsProvider = FutureProvider<List<RiskReviewOut>>(
  (ref) => ref
      .watch(restClientProvider)
      .riskReviews
      .listRiskReviewsV1RiskReviewsGet(),
);
