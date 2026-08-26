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

/// The centre's risk reviews.
///
/// It is a `risk_review` notice's destination, and also the only screen where
/// **why** one was raised can be read: the notice does not say so on purpose,
/// because it is read on a lock screen and sometimes with somebody standing
/// next to you.
///
/// Each card is a decision, so it carries its reason in sight and the
/// approve/reject pair within thumb's reach. The ones already resolved go to
/// the bottom: they stay readable and stop competing with what is waiting.
class RiskReviewsView extends ConsumerWidget {
  const RiskReviewsView({super.key, this.highlightIntakeId});

  /// The capture behind the notice that brought somebody here. The review it
  /// belongs to is highlighted, so nobody has to hunt for it in a list.
  final String? highlightIntakeId;

  static Route<void> route({String? highlightIntakeId}) =>
      MaterialPageRoute<void>(
        builder: (_) => RiskReviewsView(highlightIntakeId: highlightIntakeId),
      );

  /// Closes a review with whatever coordination decides.
  ///
  /// Somebody else having resolved it from the panel while this screen was open
  /// is normal: the server says so and that text is shown as it is, instead of
  /// a generic error that explains nothing.
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
      Text(context.l10n.reviewsTitle),
      Text(
        context.l10n.reviewsSubtitle,
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
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(context.l10n.reviewsEmpty, textAlign: TextAlign.center),
          ),
        for (final review in pending)
          _ReviewCard(
            review: review,
            highlighted: review.intakeId == highlightIntakeId,
            onResolve: onResolve == null ? null : () => onResolve!(review),
          ),
        if (settled.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.reviewsSettledHeading,
            style: Theme.of(context).textTheme.titleSmall,
          ),
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

  /// Null for somebody who does not coordinate: the server requires that role
  /// to resolve.
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
                context.l10n.reviewFromNoticeHint,
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 6),
            ],
            Text(review.kind, style: theme.textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(
              [
                // The contract declares it as text, so it is only read as a
                // count when it really is one.
                if (review.boxes case final boxes?)
                  switch (int.tryParse(boxes)) {
                    final count? => context.l10n.boxCount(count),
                    _ => boxes,
                  },
                formatShortDate(review.createdAt),
              ].join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            // The reason in quotes and exactly as the server worded it: it is
            // all that explains why this capture is here, and rewriting it
            // would be opining on a rule that is not ours.
            if (review.reason case final reason?) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.quoted(reason),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (review.reviewNote case final note?) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.reviewNoteLine(note),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (onResolve case final onResolve?) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onResolve,
                  child: Text(context.l10n.reviewDecideAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A review already decided. It is kept because knowing that something was
/// approved, and with what note, is half the value of having flagged it.
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
