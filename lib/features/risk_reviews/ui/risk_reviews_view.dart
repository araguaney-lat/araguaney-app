import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/risk_review_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../data/risk_reviews_providers.dart';
import '../data/risk_reviews_repository.dart';
import 'resolve_review_sheet.dart';

/// Revisiones de riesgo del centro.
///
/// Es el destino de un aviso `risk_review`, y también la única pantalla donde
/// se puede leer **por qué** se levantó una: el aviso no lo dice a propósito,
/// porque se lee en una pantalla de bloqueo y a veces con alguien al lado.
///
/// Cada tarjeta es una decisión, así que lleva su motivo a la vista y el par
/// aprobar/rechazar al alcance del pulgar. Las que ya se resolvieron bajan al
/// final: siguen consultables y dejan de competir con lo que espera.
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(failure.operatorMessage(context.l10n))),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(riskReviewsProvider);
    final canResolve = ref.watch(isCenterCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(title: const _Header()),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(riskReviewsProvider),
        child: switch (reviews) {
          AsyncData(:final value) => _Loaded(
            reviews: value,
            highlightIntakeId: highlightIntakeId,
            onResolve: canResolve
                ? (review) => _resolve(context, ref, review)
                : null,
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Revisiones'),
      Text(
        'Capturas marcadas que esperan una decisión',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.reviews,
    required this.highlightIntakeId,
    required this.onResolve,
  });

  final List<RiskReviewOut> reviews;
  final String? highlightIntakeId;
  final void Function(RiskReviewOut review)? onResolve;

  @override
  Widget build(BuildContext context) {
    final pending = reviews.where((r) => r.status == 'PENDING').toList();
    final settled = reviews.where((r) => r.status != 'PENDING').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (pending.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nada espera una decisión. Aquí aparecen las capturas que el '
              'servidor marcó para que alguien las mire.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final review in pending)
          _ReviewCard(
            review: review,
            highlighted: review.intakeId == highlightIntakeId,
            onResolve: onResolve == null ? null : () => onResolve!(review),
          ),
        if (settled.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Ya resueltas', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final review in settled) _SettledRow(review: review),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.highlighted,
    required this.onResolve,
  });

  final RiskReviewOut review;
  final bool highlighted;

  /// Nulo para quien no coordina: el servidor exige ese rol para resolver.
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted) ...[
              Text(
                'La del aviso que abriste',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
            ],
            Text(review.kind, style: theme.textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(
              [
                if (review.boxes case final boxes?) '$boxes cajas',
                formatShortDate(review.createdAt),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            // El motivo entre comillas y tal como lo redactó el servidor: es lo
            // único que explica por qué esta captura está aquí, y reescribirlo
            // sería opinar sobre una regla que no es nuestra.
            if (review.reason case final reason?) ...[
              const SizedBox(height: 10),
              Text('«$reason»', style: theme.textTheme.bodyMedium),
            ],
            if (review.reviewNote case final note?) ...[
              const SizedBox(height: 8),
              Text('Nota: $note', style: theme.textTheme.bodySmall),
            ],
            if (onResolve case final onResolve?) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onResolve,
                  child: const Text('Aprobar o rechazar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una revisión ya decidida. Se conserva porque saber que algo se aprobó, y con
/// qué nota, es la mitad del valor de haberlo marcado.
class _SettledRow extends StatelessWidget {
  const _SettledRow({required this.review});

  final RiskReviewOut review;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(review.kind),
    subtitle: Text(
      [formatShortDate(review.createdAt), ?review.reviewNote].join(' · '),
    ),
    trailing: Chip(label: Text(reviewStatusLabel(context.l10n, review.status))),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
