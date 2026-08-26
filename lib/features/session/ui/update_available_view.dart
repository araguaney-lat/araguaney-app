import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/client_version_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import 'app_version_footer.dart';
import 'store_link.dart';

/// There is a newer version, and the installed one still works.
///
/// **It only appears when the application opens, never mid-shift.** A notice
/// next to a lorry, with somebody scanning, is dismissed without being read —
/// and worse, it teaches dismissing, so the day the wall arrives it arrives as
/// a surprise. At launch, on the other hand, nothing has been started yet and
/// the cost of interrupting is close to zero. This is not effective because of
/// how often it shows; it is effective because of when.
///
/// It says the queued captures survive because that is the real fear of
/// somebody with unsent work, and without saying it «Más tarde» is the only
/// reasonable answer.
///
/// Unlike the wall, this one **can be left**: the installed version works, and
/// whoever decides to carry on is risking nothing the server will not accept.
class UpdateAvailableView extends ConsumerWidget {
  const UpdateAvailableView({super.key, required this.latest});

  final String? latest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/icon/ic_mark_lg.png',
                    height: 72,
                    fit: BoxFit.fitHeight,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: context.l10n.appTitle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.updateAvailableTitle,
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    latest == null
                        ? context.l10n.updateAvailableGeneric
                        : context.l10n.updateAvailableNamed(latest!),
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => openStore(context, ref),
                    child: Text(context.l10n.updateAction),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _later(ref),
                    child: Text(context.l10n.updateLaterAction),
                  ),
                  const SizedBox(height: 24),
                  const AppVersionFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _later(WidgetRef ref) async {
    // The order matters: first it gets out of the way, and recording the snooze
    // comes after. If writing to the preferences failed, the worst that happens
    // is the notice coming back at the next launch — not the person left
    // staring at a screen that will not close.
    ref.read(updatePromptDismissedProvider.notifier).state = true;
    if (latest == null) return;
    await ref.read(updatePromptMemoryProvider).snooze(latest!, DateTime.now());
  }
}
