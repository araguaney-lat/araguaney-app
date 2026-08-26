import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import 'app_version_footer.dart';
import 'store_link.dart';

/// The wall: this build is no longer supported by the backend.
///
/// **It is the only screen in the application that cannot be left.** There is
/// no back arrow, no «carry on anyway» and no way to reach the sign-in screen,
/// because the contract no longer guarantees that what this version sends is
/// understood the same way. Letting people carry on «at your own risk» would
/// hand whoever operates a decision they have no way to weigh, and the cost of
/// getting it wrong is paid by a centre's inventory.
///
/// It is only reached when the server said so. A failure of the check never
/// brings anybody to this screen: see `clientVersionStatusProvider`.
class UpdateRequiredView extends ConsumerWidget {
  const UpdateRequiredView({super.key});

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
                    context.l10n.updateRequiredTitle,
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.updateRequiredExplanation,
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => openStore(context, ref),
                    child: Text(context.l10n.updateAction),
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
}
