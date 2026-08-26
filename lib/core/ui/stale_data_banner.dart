import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_controller.dart';
import '../i18n/generated/app_localizations.dart';
import '../i18n/l10n_extension.dart';
import 'relative_time.dart';

/// A notice that what is on screen may not be the latest.
///
/// It appears when there is no connection or when the last refresh attempt
/// failed. Staying quiet in those cases would be worse than showing old data:
/// whoever operates decides differently when they know the box they are looking
/// at was synced yesterday.
class StaleDataBanner extends ConsumerWidget {
  const StaleDataBanner({
    super.key,
    required this.lastSyncedAt,
    this.lastFailureCode,
    this.now,
  });

  final DateTime? lastSyncedAt;
  final String? lastFailureCode;

  /// An injectable clock so tests do not depend on the moment they run.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityControllerProvider);
    final offline = status == ConnectivityStatus.offline;
    if (!offline && lastFailureCode == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              offline ? Icons.cloud_off : Icons.sync_problem,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _message(context.l10n, offline),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(AppLocalizations l10n, bool offline) {
    final headline = offline ? l10n.offlineHeadline : l10n.staleHeadline;
    final moment = lastSyncedAt;

    if (moment == null) return l10n.staleNothingDownloaded(headline);
    return l10n.staleWithAge(
      headline,
      describeAge(l10n, moment, (now ?? DateTime.now)()),
    );
  }
}
