import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/client_version_gate.dart';
import '../../../core/api/client_version_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';

/// The installed version, at the foot.
///
/// **It exists so that asking «which version do you have?» stops costing a
/// conversation.** Whoever operates does not know — and has no reason to know —
/// which build the store gave them, and without this figure diagnosing anything
/// starts by finding out. It goes on the sign-in screen because that is the one
/// everybody sees before being able to do anything, including the person who
/// cannot get in yet.
///
/// It carries the build number as well as the name: `1.0.0 (3)`. The name
/// repeats between published versions and the one that identifies a binary is
/// the second, which is exactly the one needed to know what is being looked at.
class AppVersionFooter extends ConsumerWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider);
    final build = ref.watch(appBuildNumberProvider);
    // The update-available notice lives here and not in a card or a dialog:
    // there is a new one, nothing happens by carrying on, and an interruption
    // would be out of proportion. The wall is another thing and has its own
    // screen.
    // `valueOrNull`, for the same reason as in `SessionGate`: `value` rethrows
    // on an `AsyncError` and would take the whole sign-in down for failing to
    // look up a version.
    final outdated =
        ref.watch(clientVersionStatusProvider).valueOrNull?.status ==
        ClientVersionStatus.updateAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          build.isEmpty
              ? context.l10n.appVersion(version)
              : context.l10n.appVersionWithBuild(version, build),
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (outdated) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.updateAvailableFooter,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
