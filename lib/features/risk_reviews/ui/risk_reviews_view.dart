import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/risk_review_out.dart';
import '../../../core/ui/record_field.dart';
import '../data/risk_reviews_providers.dart';

/// Revisiones de riesgo del centro.
///
/// Es el destino de un aviso `risk_review`, y también la única pantalla donde
/// se puede leer **por qué** se levantó una: el aviso no lo dice a propósito,
/// porque se lee en una pantalla de bloqueo y a veces con alguien al lado.
class RiskReviewsView extends ConsumerWidget {
  const RiskReviewsView({super.key, this.highlightIntakeId});

  /// La captura que motivó el aviso que trajo a alguien hasta aquí. La revisión
  /// que le corresponde se marca, para no obligar a buscarla en una lista.
  final String? highlightIntakeId;

  static Route<void> route({String? highlightIntakeId}) =>
      MaterialPageRoute<void>(
        builder: (_) => RiskReviewsView(highlightIntakeId: highlightIntakeId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(riskReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revisiones de riesgo')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(riskReviewsProvider),
        child: switch (reviews) {
          AsyncData(:final value) when value.isEmpty => const _Message(
            'No hay revisiones abiertas sobre las capturas de este centro.',
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _ReviewTile(
              review: value[index],
              highlighted:
                  highlightIntakeId != null &&
                  value[index].intakeId == highlightIntakeId,
            ),
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.highlighted});

  final RiskReviewOut review;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: highlighted ? scheme.secondaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'La del aviso que abriste',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          RecordField(label: 'Motivo', value: review.reason ?? review.kind),
          RecordField(label: 'Estado', value: review.status),
          RecordField(
            label: 'Abierta',
            value: formatShortDate(review.createdAt),
          ),
          if (review.boxes case final boxes?)
            RecordField(label: 'Cajas', value: boxes),
          if (review.reviewNote case final note?)
            RecordField(label: 'Nota de la revisión', value: note),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
