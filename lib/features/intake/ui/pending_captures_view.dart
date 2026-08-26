import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/refusal_copy.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/tables/queued_captures_table.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/sync/sync_outcome.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../catalog/data/catalog_providers.dart';
import '../data/capture_queue_sync.dart';
import '../data/intake_providers.dart';
import '../domain/queued_capture_lines.dart';

/// The captures waiting for signal.
///
/// The screen exists so the queue is not invisible: a capture nobody can see is
/// a capture nobody knows was lost. Nothing is discarded on its own — a refused
/// one stays here with the server's reason — and both discarding and retrying
/// are asked for by a person.
class PendingCapturesView extends ConsumerStatefulWidget {
  const PendingCapturesView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PendingCapturesView());

  @override
  ConsumerState<PendingCapturesView> createState() =>
      _PendingCapturesViewState();
}

class _PendingCapturesViewState extends ConsumerState<PendingCapturesView> {
  bool _flushing = false;

  Future<void> _flush() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _flushing = true);
    final report = await ref.read(captureQueueSyncProvider).flush(userId);
    if (!mounted) return;
    setState(() => _flushing = false);

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(_reportMessage(context.l10n, report))),
    );
  }

  /// What is said to whoever pressed «sincronizar». The server's reason wins
  /// over the count: knowing there is no signal is more useful than knowing
  /// nothing was sent.
  static String _reportMessage(AppLocalizations l10n, QueueFlushReport report) {
    if (report.stoppedBy case final failure?) {
      return failure.operatorMessage(l10n);
    }
    if (report.sent > 0 && report.remaining == 0) {
      return l10n.queueSentAllDone(report.sent);
    }
    if (report.sent > 0) return l10n.queueSent(report.sent);
    if (report.parked > 0) {
      return l10n.queueParkedByServer(report.parked);
    }
    return l10n.nothingToSend;
  }

  Future<void> _discard(QueuedCaptureRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.discardCaptureConfirmTitle),
        content: Text(
          context.l10n.discardCaptureExplanation(_summary(context.l10n, row)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.keepAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.discardAction),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(captureQueueRepositoryProvider).discard(row.captureId);
    }
  }

  /// Putting a parked capture back in the queue. It is not asked about first
  /// because it destroys nothing: it tries again with the same capture key,
  /// and if the reason still stands the server will park it again with the same
  /// text.
  Future<void> _retry(QueuedCaptureRow row) async {
    await ref.read(captureQueueRepositoryProvider).retry(row.captureId);
    if (!mounted) return;
    await _flush();
  }

  @override
  Widget build(BuildContext context) {
    final captures = ref.watch(queuedCapturesProvider);
    final products = ref.watch(productTypesProvider(null)).valueOrNull ?? [];
    final codes = ref.watch(availableBoxCodesProvider).valueOrNull ?? 0;
    final queued = captures.valueOrNull?.length ?? 0;

    final names = {
      for (final product in products) product.id: product.displayName,
    };

    return Scaffold(
      appBar: AppBar(
        title: const _Header(),
        bottom: _flushing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: switch (captures) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReadinessStrip(
              products: products.length,
              codes: codes,
              queued: queued,
            ),
            const SizedBox(height: 12),
            _Actions(onSync: _flushing ? null : _flush),
            const SizedBox(height: 16),
            if (value.isEmpty)
              const _Empty()
            else
              for (final row in value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QueuedCard(
                    row: row,
                    lines: queuedCaptureLines(row.payload, names),
                    onRetry: () => _retry(row),
                    onDiscard: () => _discard(row),
                  ),
                ),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
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
      Text(context.l10n.pendingCapturesTitle),
      Text(
        context.l10n.queueNothingIsLost,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// What there is to work with without signal, in three numbers.
///
/// They sit together because they are read together: going down to a basement
/// with a catalogue but no codes, or with codes but a full queue, are different
/// situations and neither is visible from one number alone.
class _ReadinessStrip extends StatelessWidget {
  const _ReadinessStrip({
    required this.products,
    required this.codes,
    required this.queued,
  });

  final int products;
  final int codes;
  final int queued;

  // `IntrinsicHeight` so the three cells measure the same: their labels break
  // into a different number of lines, and three boxes of different heights read
  // as three different things, which is exactly the opposite of what they are.
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Cell(
            label: context.l10n.cachedProductsLabel,
            value: products,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Cell(label: context.l10n.reservedCodesLabel, value: codes),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Cell(label: context.l10n.queuedCapturesLabel, value: queued),
        ),
      ],
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: palette.noticeFill,
        border: Border.all(color: palette.noticeBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.noticeInk,
            ),
          ),
          // At the bottom of the cell, not below the label: «Capturas en cola»
          // fits on one line and the other two labels break into two, so
          // resting against the top left the three numbers at different
          // heights and the row stopped reading as a row.
          const Spacer(),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: palette.noticeInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.onSync});

  final VoidCallback? onSync;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  static const _blockSize = 50;
  bool _reserving = false;

  /// They are topped up **with** signal, which is the only moment it can be
  /// done: whoever goes down to a basement with an empty block is left without
  /// labels until they come back up.
  Future<void> _topUp() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _reserving = true);
    final outcome = await ref
        .read(boxCodeRepositoryProvider)
        .topUp(
          count: _blockSize,
          userId: userId,
          centerId: ref.read(writeCenterIdProvider),
        );
    if (!mounted) return;
    setState(() => _reserving = false);

    final message = switch (outcome) {
      SyncSucceeded(:final itemCount) => context.l10n.codesReserved(itemCount),
      SyncFailed(:final failure) => failure.operatorMessage(context.l10n),
    };
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: ConfirmButton(
          label: context.l10n.syncAction,
          onPressed: widget.onSync,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: OutlinedButton(
          onPressed: _reserving ? null : _topUp,
          child: Text(context.l10n.reserveCodesAction),
        ),
      ),
    ],
  );
}

/// How a queued capture is named.
///
/// The count is rendered here and not stored: the row keeps the number, and the
/// words for it belong to whatever language the application is in when somebody
/// opens this screen.
String _summary(AppLocalizations l10n, QueuedCaptureRow row) {
  final boxes = l10n.boxCount(row.boxCount);
  return row.summary.isEmpty ? boxes : '$boxes · ${row.summary}';
}

class _QueuedCard extends StatelessWidget {
  const _QueuedCard({
    required this.row,
    required this.lines,
    required this.onRetry,
    required this.onDiscard,
  });

  final QueuedCaptureRow row;
  final List<String> lines;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rejected = row.status == QueuedCaptureStatus.rejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _summary(context.l10n, row),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _when(context.l10n, row),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(rejected: rejected),
              ],
            ),
            if (lines.isNotEmpty) const SizedBox(height: 10),
            for (final line in lines)
              Text('· $line', style: theme.textTheme.bodySmall),
            // Our own copy when we know the code, and otherwise the words the
            // server sent. What is stored is always the second: see
            // `capture_queue_sync`.
            if (refusalCopyFor(context.l10n, row.lastFailureCode ?? '') ??
                    row.lastFailureMessage
                case final message?) ...[
              const SizedBox(height: 10),
              Text(message, style: theme.textTheme.bodyMedium),
            ],
            // Retrying and discarding only appear on a parked capture. One
            // still waiting for signal needs nobody to decide anything: it
            // retries itself as soon as there is a network.
            if (rejected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetry,
                      child: Text(context.l10n.actionRetry),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextButton(
                      onPressed: onDiscard,
                      child: Text(context.l10n.discardAction),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// When it was captured and how many times it has been attempted.
  ///
  /// With no denominator: the queue retries while there is a reason to and has
  /// no maximum. Writing «intento 1 de 5» would put a limit on screen that this
  /// system does not have.
  static String _when(AppLocalizations l10n, QueuedCaptureRow row) => [
    formatShortDateTime(row.createdAt),
    if (row.attempts > 0)
      l10n.attemptNumber(row.attempts)
    else
      l10n.noAttemptsYet,
  ].join(' · ');
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.rejected});

  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: rejected ? palette.alertFill : palette.noticeFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rejected
            ? context.l10n.queueStatusRejected
            : context.l10n.queueStatusPending,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: rejected ? palette.alertInk : palette.noticeInk,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Text(
      context.l10n.queueEmpty,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}
