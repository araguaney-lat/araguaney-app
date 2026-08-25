import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../../core/ui/sheet_insets.dart';

/// Rechazar una postulación, con su motivo.
///
/// **Lo que se escriba aquí lo va a leer quien postuló**, en un correo, fuera
/// de la plataforma y probablemente sin más contexto que esa frase. Por eso el
/// campo es obligatorio —el servidor también lo exige— y por eso la pantalla
/// dice a dónde va antes de que alguien empiece a escribir.
class RejectApplicationSheet extends StatefulWidget {
  const RejectApplicationSheet({super.key, required this.centerName});

  final String centerName;

  static Future<String?> show(
    BuildContext context, {
    required String centerName,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RejectApplicationSheet(centerName: centerName),
  );

  @override
  State<RejectApplicationSheet> createState() => _RejectApplicationSheetState();
}

class _RejectApplicationSheetState extends State<RejectApplicationSheet> {
  final _reason = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    setState(() => _tried = true);
    if (reason.isEmpty) return;
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final empty = _tried && _reason.text.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: sheetBottomInset(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Rechazar ${widget.centerName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.applicationRejectReasonHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: context.l10n.reasonLabel,
              errorText: empty ? 'Escribe el motivo del rechazo' : null,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(context.l10n.actionReject),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionCancel),
          ),
        ],
      ),
    );
  }
}
