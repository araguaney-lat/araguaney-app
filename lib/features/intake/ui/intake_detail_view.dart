import 'package:flutter/material.dart';

import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/ui/record_field.dart';
import '../../boxes/ui/box_label_view.dart';
import '../../boxes/ui/box_status_label.dart';
import 'intake_list_view.dart';

/// Una captura registrada, con las cajas que produjo.
///
/// Cada caja lleva a su etiqueta: una captura vieja cuya caja perdió el papel
/// se vuelve a etiquetar desde aquí sin pasar por el panel.
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
        RecordField(label: 'Donante', value: donorLabel(intake) ?? 'Anónimo'),
        if (intake.notes case final notes?)
          RecordField(label: 'Notas', value: notes),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Cajas', style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final box in intake.boxes)
          ListTile(
            title: Text(box.code),
            subtitle: Text(
              '${box.quantity} ${box.unit} · ${boxStatusLabel(box.status)}',
            ),
            trailing: const Icon(Icons.qr_code_2),
            onTap: () =>
                Navigator.of(context).push(BoxLabelView.route(box.code)),
          ),
      ],
    ),
  );
}
