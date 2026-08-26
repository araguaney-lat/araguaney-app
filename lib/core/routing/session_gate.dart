import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/centers/ui/choose_center_view.dart';
import '../../features/session/ui/change_password_view.dart';
import '../../features/session/ui/login_view.dart';
import '../../features/session/ui/totp_challenge_view.dart';
import '../../features/session/ui/update_available_view.dart';
import '../../features/session/ui/update_required_view.dart';
import '../../features/shell/ui/app_shell.dart';
import '../api/client_version_gate.dart';
import '../api/client_version_providers.dart';
import '../auth/auth_providers.dart';
import '../auth/session.dart';
import '../center/center_providers.dart';
import '../ui/brand_splash.dart';
import 'push_router.dart';

/// Decides what is on screen according to the state of the session.
///
/// Unauthenticated navigation does not exist: there is no route to reach
/// without a session and bounce off, only one place that decides. That way no
/// screen is left reachable by accident from a link or a `pop`.
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This comes before the session, and only when the server said so: while
    // the check is in flight, or if it failed, this is not `updateRequired` and
    // nothing looks different. Nobody is locked out by a request that never
    // arrived.
    // `valueOrNull` and not `value`: on an `AsyncError` the second one
    // **rethrows**, which would turn a failed check into an error screen —
    // exactly what this gate promises not to do.
    final version = ref.watch(clientVersionStatusProvider).valueOrNull;

    // The wall goes first and takes nothing ahead of it: below the minimum,
    // the contract no longer guarantees this build is understood.
    if (version?.status == ClientVersionStatus.updateRequired) {
      return const UpdateRequiredView();
    }

    // The notice comes after, and only at start-up. It is dismissed for the
    // rest of the process's life as soon as somebody sees it, so a change of
    // session — signing in, a forced password change — does not bring it back
    // halfway through a shift.
    if (version?.status == ClientVersionStatus.updateAvailable &&
        !ref.watch(updatePromptDismissedProvider) &&
        !(ref.watch(updateSnoozedProvider).valueOrNull ?? true)) {
      return UpdateAvailableView(latest: version?.latest);
    }

    final state = ref.watch(sessionControllerProvider);

    return switch (state) {
      SessionRestoring() => const BrandSplash(),
      SessionAbsent() => const LoginView(),
      SessionAwaitingTotp() => const TotpChallengeView(),
      // The forced change comes even with a valid session: the server requires
      // it, and skipping it would leave a temporary password alive.
      SessionActive(:final session) when session.mustChangePassword =>
        const ChangePasswordView(),
      // A national administration belongs to no centre, and the server
      // requires one to be **named** on every create. Asking here rather than
      // in the first form is what keeps the application from reading as if it
      // all worked until something is written.
      SessionActive() when ref.watch(workingCenterPendingProvider) =>
        const BrandSplash(),
      SessionActive() when ref.watch(needsWorkingCenterProvider) =>
        const ChooseCenterView(),
      // Notice routing wraps this branch only: navigating requires a session,
      // and neither signing in nor a forced password change can be skipped
      // because somebody tapped a notification.
      SessionActive() => const PushRouter(child: AppShell()),
    };
  }
}
