import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/risk_review_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/ui/record_field.dart';
import '../data/risk_reviews_providers.dart';
import '../data/risk_reviews_repository.dart';
import 'resolve_review_sheet.dart';

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

  /// Cierra una revisión con lo que decida quien coordina.
  ///
  /// Que otra persona la haya resuelto desde el panel mientras esta pantalla
  /// estaba abierta es normal: el servidor lo dice y ese texto se muestra tal
  /// cual, en vez de un error genérico que no explica nada.
  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    RiskReviewOut review,
  ) async {
    final decision = await ResolveReviewSheet.show(
      context,
      reason: review.reason ?? review.kind,
    );
    if (decision == null || !context.mounted) return;

    final outcome = await ref
        .read(riskReviewsRepositoryProvider)
        .resolve(
          reviewId: review.id,
          resolution: decision.resolution,
          note: decision.note,
        );
    if (!context.mounted) return;

    ref.invalidate(riskReviewsProvider);
    if (outcome case ResolveRefused(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.operatorMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(riskReviewsProvider);
    final canResolve = ref.watch(isCenterCoordinatorProvider);

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
              onResolve: canResolve
                  ? () => _resolve(context, ref, value[index])
                  : null,
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
  const _ReviewTile({
    required this.review,
    required this.highlighted,
    this.onResolve,
  });

  final RiskReviewOut review;
  final bool highlighted;

  /// Nulo para quien no coordina: el servidor exige ese rol para resolver.
  final VoidCallback? onResolve;

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
          if (onResolve case final onResolve?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: onResolve,
                  child: const Text('Resolver'),
                ),
              ),
            )
          else
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
