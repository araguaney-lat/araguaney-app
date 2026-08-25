import 'package:flutter/material.dart';

import '../../../core/api/generated/models/intake_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../boxes/ui/box_label_view.dart';
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
        RecordField(
          label: context.l10n.intakeDonante,
          value: donorLabel(intake) ?? 'Anónimo',
        ),
        if (intake.notes case final notes?)
          RecordField(label: context.l10n.intakeNotas, value: notes),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            context.l10n.boxesCajas,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // Una captura recién registrada sí trae sus cajas, porque las devuelve
        // el `POST`. Una abierta desde el historial no: el listado del servidor
        // no las rellena, y por eso aquí se dice en vez de enseñar una sección
        // vacía, que se leería como «esta captura no tuvo cajas».
        if (intake.boxes.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(context.l10n.intakeElHistorialNoTraeLas),
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
