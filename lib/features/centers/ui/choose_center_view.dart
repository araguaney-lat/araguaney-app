import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/center/working_center.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../data/centers_providers.dart';
import '../data/centers_repository.dart';

/// Where a national administrator says which centre they are working in.
///
/// It is asked once, right after signing in, and not per capture. Somebody
/// registering ten donations is standing in one warehouse for all ten, and
/// asking every time would turn the answer into a reflex — which is the failure
/// mode of asking too often, not a defence against it.
///
/// The price of asking once is that the answer has to stay visible. That is not
/// this screen's job: it is the reminder on every screen that writes.
class ChooseCenterView extends ConsumerWidget {
  const ChooseCenterView({super.key, this.canDismiss = false});

  /// False when this is the gate after signing in, where there is nothing
  /// behind to go back to. True when it was opened from the menu to change.
  final bool canDismiss;

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const ChooseCenterView(canDismiss: true),
  );

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    CenterOut center,
  ) async {
    await ref
        .read(workingCenterProvider.notifier)
        .choose(WorkingCenter(id: center.id, name: center.name));
    if (context.mounted && canDismiss) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final centers = ref.watch(centersProvider);
    final current = ref.watch(workingCenterProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.workingCenterTitle),
        automaticallyImplyLeading: canDismiss,
      ),
      body: switch (centers) {
        AsyncData(value: CentersRead(:final value)) => _List(
          centers: value,
          currentId: current?.id,
          onChoose: (center) => _choose(context, ref, center),
        ),
        AsyncData(value: CentersRefused(:final failure)) => _Message(
          failure.operatorMessage(context.l10n),
          onRetry: () => ref.invalidate(centersProvider),
        ),
        AsyncError() => _Message(
          context.l10n.workingCenterUnavailable,
          onRetry: () => ref.invalidate(centersProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.centers,
    required this.currentId,
    required this.onChoose,
  });

  final List<CenterOut> centers;
  final String? currentId;
  final ValueChanged<CenterOut> onChoose;

  @override
  Widget build(BuildContext context) {
    // Only the active ones. A centre that was closed is not a place where
    // anybody is receiving donations today, and offering it would produce a
    // refusal from the server one screen later.
    final open = centers.where((center) => center.isActive).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (open.isEmpty) return _Message(context.l10n.workingCenterEmpty);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.workingCenterQuestion,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.workingCenterExplanation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        for (final center in open)
          ListTile(
            leading: const Icon(Icons.apartment_outlined),
            title: Text(center.name),
            subtitle: switch (_place(center)) {
              final place? => Text(place),
              _ => null,
            },
            trailing: center.id == currentId ? const Icon(Icons.check) : null,
            onTap: () => onChoose(center),
          ),
      ],
    );
  }

  static String? _place(CenterOut center) {
    final parts = [
      center.stateName,
      center.countryCode,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (onRetry case final retry?) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: retry,
              child: Text(context.l10n.actionRetry),
            ),
          ],
        ],
      ),
    ),
  );
}
