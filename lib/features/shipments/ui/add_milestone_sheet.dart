import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../data/shipments_repository.dart';

/// Anotar un hito del viaje.
///
/// Es la operación con el caso móvil más claro de toda la fase, y no está
/// cerca: alguien está junto a un camión, en un puesto de control, sin
/// escritorio. Un hito no mueve el estado del envío — registra que algo pasó.
///
/// **La fecha es opcional y por eso existe.** El reporte del consignatario
/// suele llegar tarde y describir algo de ayer; obligar a que todo hito sea
/// «ahora» convertiría el registro en una lista de cuándo alguien tuvo señal.
class AddMilestoneSheet extends StatefulWidget {
  const AddMilestoneSheet({super.key});

  static Future<({String milestone, String? note, DateTime? occurredAt})?> show(
    BuildContext context,
  ) =>
      showModalBottomSheet<
        ({String milestone, String? note, DateTime? occurredAt})
      >(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const AddMilestoneSheet(),
      );

  @override
  State<AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends State<AddMilestoneSheet> {
  final _note = TextEditingController();
  String? _milestone;
  DateTime? _occurredAt;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _occurredAt ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      // Un hito describe algo que ya pasó.
      lastDate: now,
    );
    if (chosen != null) setState(() => _occurredAt = chosen);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 8,
      bottom: sheetBottomInset(context),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.milestoneAddTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _milestone,
          decoration: InputDecoration(labelText: context.l10n.milestoneLabel),
          items: [
            for (final milestone in shipmentMilestones)
              DropdownMenuItem(
                value: milestone,
                child: Text(milestoneLabel(context.l10n, milestone)),
              ),
          ],
          onChanged: (value) => setState(() => _milestone = value),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.milestoneWhenLabel),
          subtitle: Text(
            _occurredAt == null
                ? context.l10n.milestoneWhenDefault
                : formatShortDate(_occurredAt!),
          ),
          trailing: const Icon(Icons.event),
          onTap: _pickDate,
        ),
        TextField(
          controller: _note,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: context.l10n.optionalField(context.l10n.notesLabel),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _milestone == null
              ? null
              : () => Navigator.of(context).pop((
                  milestone: _milestone!,
                  note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                  occurredAt: _occurredAt,
                )),
          child: Text(context.l10n.milestoneAddAction),
        ),
      ],
    ),
  );
}
