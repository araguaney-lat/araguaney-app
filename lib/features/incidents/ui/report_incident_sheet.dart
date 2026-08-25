import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../../core/ui/sheet_insets.dart';
import '../data/incidents_repository.dart';

/// Levantar una incidencia sobre un envío.
///
/// Quien envió es quien nota lo que falta, y por eso esto vive en el móvil: se
/// escribe en el andén, con el bulto delante, no al volver a un escritorio.
class ReportIncidentSheet extends StatefulWidget {
  const ReportIncidentSheet({super.key});

  static Future<({String type, String description})?> show(
    BuildContext context,
  ) => showModalBottomSheet<({String type, String description})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const ReportIncidentSheet(),
  );

  @override
  State<ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<ReportIncidentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _type = IncidentType.damage;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((type: _type, description: _description.text.trim()));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: sheetBottomInset(context),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.incidentRaiseTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: context.l10n.typeLabel),
            items: [
              for (final type in IncidentType.all)
                DropdownMenuItem(
                  value: type,
                  child: Text(incidentTypeLabel(type)),
                ),
            ],
            onChanged: (value) =>
                setState(() => _type = value ?? IncidentType.other),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: context.l10n.incidentDescriptionLabel,
              helperText: context.l10n.incidentDescriptionHint,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Describe lo que pasó'
                : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submit,
              child: Text(context.l10n.incidentRaiseAction),
            ),
          ),
        ],
      ),
    ),
  );
}
