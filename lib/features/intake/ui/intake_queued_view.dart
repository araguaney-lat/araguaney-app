import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../boxes/ui/box_label_view.dart';
import '../domain/intake_draft.dart';

/// Lo que se ve cuando una captura queda esperando señal.
///
/// Su trabajo es el mismo que el de la pantalla de captura aceptada: que las
/// cajas se etiqueten antes de moverse. La diferencia es de dónde salen los
/// códigos — de un bloque reservado con señal — y que aquí se dice con todas
/// las letras que la captura todavía no llegó a ningún sitio.
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
      appBar: AppBar(title: Text(context.l10n.intakeCapturaGuardada)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.intakeSeEnviaraSolaCuandoHaya,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.intakeNoHaceFaltaVolverA,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (withCode.isNotEmpty) ...[
            Text(
              context.l10n.intakeEtiquetaEstasCajasAhora,
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
                  withoutCode == 1
                      ? 'Una caja quedó sin código: el bloque reservado se '
                            'agotó. Recibirá el suyo cuando la captura llegue '
                            'al servidor, y habrá que etiquetarla entonces.'
                      : '$withoutCode cajas quedaron sin código porque el '
                            'bloque reservado se agotó. Recibirán el suyo '
                            'cuando la captura llegue al servidor, y habrá que '
                            'etiquetarlas entonces.',
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
