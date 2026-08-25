import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

/// Qué se hace cuando el servidor pide identificar a quien dona.
enum DonorRequestOutcome {
  /// Se va a registrar al donante.
  identify,

  /// Quien dona no quiso identificarse; se registra el motivo.
  exception,
}

/// El servidor pidió identificar antes de aceptar esta captura.
///
/// No bloquea: el backend acepta la captura anónima con un motivo escrito y
/// deja la revisión abierta para la coordinación. Detener aquí a quien captura
/// le trasladaría el costo a la operación en plena jornada y no recuperaría
/// nada — para cuando alguien revisara, la persona ya se fue.
class AnonymousExceptionDialog extends StatefulWidget {
  const AnonymousExceptionDialog({super.key, required this.serverMessage});

  final String serverMessage;

  static Future<({DonorRequestOutcome outcome, String? reason})?> show(
    BuildContext context, {
    required String serverMessage,
  }) => showDialog<({DonorRequestOutcome outcome, String? reason})>(
    context: context,
    builder: (_) => AnonymousExceptionDialog(serverMessage: serverMessage),
  );

  @override
  State<AnonymousExceptionDialog> createState() =>
      _AnonymousExceptionDialogState();
}

class _AnonymousExceptionDialogState extends State<AnonymousExceptionDialog> {
  final _reason = TextEditingController();
  bool _writingReason = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.intakeFaltaIdentificarAQuienDona),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El texto del servidor se muestra tal cual: describe una regla de
        // negocio que quien captura puede entender y resolver.
        Text(widget.serverMessage),
        if (_writingReason) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: context.l10n.center_applicationsMotivo,
              helperText: context.l10n.intakePorQueNoFuePosible,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    ),
    actions: _writingReason
        ? [
            TextButton(
              onPressed: () => setState(() => _writingReason = false),
              child: Text(context.l10n.sessionVolver),
            ),
            FilledButton(
              onPressed: _reason.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop((
                      outcome: DonorRequestOutcome.exception,
                      reason: _reason.text.trim(),
                    )),
              child: Text(context.l10n.intakeRegistrarSinDonante),
            ),
          ]
        : [
            TextButton(
              onPressed: () => setState(() => _writingReason = true),
              child: Text(context.l10n.intakeNoQuisoIdentificarse),
            ),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).pop((outcome: DonorRequestOutcome.identify, reason: null)),
              child: Text(context.l10n.intakeIdentificar),
            ),
          ],
  );
}
