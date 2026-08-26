import 'package:flutter/material.dart';

import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../boxes/ui/box_label_view.dart';
import 'intake_list_view.dart';

/// A registered capture, with the boxes it produced.
///
/// Every box leads to its label: an old capture whose box lost its paper is
/// relabelled from here without going through the panel.
class IntakeDetailView extends StatelessWidget {
  const IntakeDetailView({super.key, required this.intake});

  final IntakeOut intake;

  static Route<void> route(IntakeOut intake) =>
      MaterialPageRoute<void>(builder: (_) => IntakeDetailView(intake: intake));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(formatShortDate(intake.createdAt))),
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        RecordField(
          label: context.l10n.donorLabel,
          value: donorLabel(intake) ?? context.l10n.donorAnonymous,
        ),
        if (intake.notes case final notes?)
          RecordField(label: context.l10n.notesLabel, value: notes),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            context.l10n.boxesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // A freshly registered capture does bring its boxes, because the
        // `POST` returns them. One opened from the history does not: the
        // server's listing does not fill them in, and that is why it is said
        // here rather than showing an empty section, which would read as «this
        // capture had no boxes».
        if (intake.boxes.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(context.l10n.captureBoxesNotInHistory),
          ),
        for (final box in intake.boxes)
          ListTile(
            title: Text(box.code),
            subtitle: Text(
              '${box.quantity} ${box.unit} · ${boxStatusLabel(context.l10n, box.status)}',
            ),
            trailing: const Icon(Icons.qr_code_2),
            onTap: () =>
                Navigator.of(context).push(BoxLabelView.route(box.code)),
          ),
      ],
    ),
  );
}
