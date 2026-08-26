import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';

/// An invitation to turn notices on, with the reason in front.
///
/// It does not ask on the way in. A system dialog right after signing in
/// arrives with no context and is denied by reflex, and on Android a denial is
/// close to final: the application cannot ask again. So first it says which
/// notices arrive and whoever reads decides whether to open the dialog.
///
/// It disappears as soon as there is a decision, whichever it is. Denying does
/// not leave a card insisting: somebody who does not want them has already said
/// so.
///
/// «There is a decision» is decided by [shouldOfferPushProvider] and not by the
/// state the system reports. On Android that state does not tell somebody who
/// denied from somebody who was never asked, and this card — which was only
/// painted in the `notDetermined` state — never got shown at all.
class PushPermissionCard extends ConsumerStatefulWidget {
  const PushPermissionCard({super.key});

  @override
  ConsumerState<PushPermissionCard> createState() => _PushPermissionCardState();
}

class _PushPermissionCardState extends ConsumerState<PushPermissionCard> {
  bool _asking = false;

  Future<void> _ask() async {
    setState(() => _asking = true);
    // It is recorded before asking, not after: if the system dialog kills the
    // application for whatever reason, the person has already seen the
    // invitation and putting it in front of them again would be insisting.
    await ref.read(pushPromptMemoryProvider).markOffered();

    final granted =
        await ref.read(pushServiceProvider).requestPermission() ==
        PushPermission.granted;

    // With the permission just granted there may be a token that did not exist
    // before — on iOS that is the normal case — so the destination is
    // registered again. Registering is idempotent: if it was already there, it
    // costs nothing.
    if (granted) await ref.read(onSessionStartedProvider)();

    if (!mounted) return;
    setState(() => _asking = false);
    ref
      ..invalidate(pushPermissionProvider)
      ..invalidate(shouldOfferPushProvider);
  }

  @override
  Widget build(BuildContext context) {
    final offer = ref.watch(shouldOfferPushProvider).valueOrNull ?? false;
    if (!offer) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_none),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.homeNoticesTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.l10n.homeNoticesExplanation),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _asking ? null : _ask,
                child: Text(context.l10n.homeEnableNotices),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
