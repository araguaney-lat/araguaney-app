import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../boxes/ui/box_label_view.dart';
import '../domain/intake_draft.dart';

/// What is seen when a capture is left waiting for signal.
///
/// Its job is the same as that of the accepted-capture screen: getting the
/// boxes labelled before they move. The difference is where the codes come from
/// — a block reserved while there was signal — and that here it is said in so
/// many words that the capture has not reached anywhere yet.
class IntakeQueuedView extends StatelessWidget {
  const IntakeQueuedView({super.key, required this.draft});

  final IntakeDraft draft;

  static Route<void> route(IntakeDraft draft) =>
      MaterialPageRoute<void>(builder: (_) => IntakeQueuedView(draft: draft));

  @override
  Widget build(BuildContext context) {
    final withCode = draft.boxes.where((box) => box.code != null).toList();
    final withoutCode = draft.boxes.length - withCode.length;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.captureQueuedTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.queuedWillSendItself,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.captureQueuedExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (withCode.isNotEmpty) ...[
            Text(
              context.l10n.labelBoxesNowTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final box in withCode)
              Card(
                child: ListTile(
                  title: Text(box.code!),
                  subtitle: Text(
                    '${box.productType.displayName} · '
                    '${box.quantity} ${box.unit}',
                  ),
                  trailing: const Icon(Icons.qr_code_2),
                  onTap: () =>
                      Navigator.of(context).push(BoxLabelView.route(box.code!)),
                ),
              ),
          ],
          if (withoutCode > 0) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.l10n.boxesWithoutCode(withoutCode),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionFinish),
          ),
        ],
      ),
    );
  }
}
