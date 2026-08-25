import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../center/center_providers.dart';
import '../i18n/l10n_extension.dart';
import 'theme/app_theme.dart';

/// Which centre this is being registered in.
///
/// Choosing a working centre once is faster than choosing per capture, and it
/// fails badly in exactly one way: somebody forgets which centre they are «in»
/// and registers a donation into another warehouse. **The whole defence against
/// that is this line**, so it goes on every screen that writes, not in a
/// settings page.
///
/// It draws nothing for a session that belongs to a centre. There is only one
/// centre they can write to, and a permanent reminder of something that cannot
/// vary is noise that trains people to stop reading banners.
class WorkingCenterBanner extends ConsumerWidget {
  const WorkingCenterBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(workingCenterProvider).valueOrNull;
    if (center == null || ref.watch(writeCenterIdProvider) == null) {
      return const SizedBox.shrink();
    }

    final palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: palette.activePill,
      child: Row(
        children: [
          const Icon(Icons.apartment_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.workingCenterRegisteringIn(center.name),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
