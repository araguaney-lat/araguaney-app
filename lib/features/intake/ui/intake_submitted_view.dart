import 'package:flutter/material.dart';

import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../boxes/ui/box_label_view.dart';

/// What is seen when the server accepted the capture.
///
/// Its job is getting the boxes labelled before they move: the codes the server
/// assigned are here, each one a tap away from its QR.
class IntakeSubmittedView extends StatelessWidget {
  const IntakeSubmittedView({super.key, required this.intake});

  final IntakeOut intake;

  static Route<void> route(IntakeOut intake) => MaterialPageRoute<void>(
    builder: (_) => IntakeSubmittedView(intake: intake),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.captureAcceptedTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${intake.boxes.length} '
                '${intake.boxes.length == 1 ? 'caja registrada' : 'cajas registradas'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.labelBoxesInstruction,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final box in intake.boxes)
          Card(
            child: ListTile(
              title: Text(box.code),
              subtitle: Text('${box.quantity} ${box.unit}'),
              trailing: const Icon(Icons.qr_code_2),
              onTap: () =>
                  Navigator.of(context).push(BoxLabelView.route(box.code)),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionFinish),
        ),
      ],
    ),
  );
}
