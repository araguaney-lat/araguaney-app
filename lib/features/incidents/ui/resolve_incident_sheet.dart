import 'package:flutter/material.dart';

import '../../../core/ui/sheet_insets.dart';

/// Cerrar una incidencia, con su nota.
///
/// **La nota es lo único que le queda a quien la reportó.** El contrato la
/// exige y la razón es esa: alguien vio que faltaba una caja, lo dijo, y lo que
/// va a leer después es esta frase. Cerrar sin explicar convierte un reporte en
/// un silencio.
class ResolveIncidentSheet extends StatefulWidget {
  const ResolveIncidentSheet({super.key, required this.description});

  /// Lo que se reportó, a la vista mientras se cierra.
  final String description;

  static Future<String?> show(
    BuildContext context, {
    required String description,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ResolveIncidentSheet(description: description),
  );

  @override
  State<ResolveIncidentSheet> createState() => _ResolveIncidentSheetState();
}

class _ResolveIncidentSheetState extends State<ResolveIncidentSheet> {
  final _note = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _note.text.trim();
    setState(() => _tried = true);
    if (note.isEmpty) return;
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final empty = _tried && _note.text.trim().isEmpty;

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
          Text('Cerrar la incidencia', style: text.titleMedium),
          const SizedBox(height: 8),
          // Las palabras de quien la reportó, citadas: cerrar sin releerlas es
          // como se cierra la equivocada.
          Text('«${widget.description}»', style: text.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'En qué terminó',
              errorText: empty ? 'Escribe en qué terminó' : null,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _submit, child: const Text('Cerrar')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
