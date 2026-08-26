import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../../core/ui/sheet_insets.dart';

/// Closing an incident, with its note.
///
/// **The note is all that is left to whoever reported it.** The contract
/// requires it and that is the reason: somebody saw a box was missing, said so,
/// and what they are going to read afterwards is this sentence. Closing without
/// explaining turns a report into a silence.
class ResolveIncidentSheet extends StatefulWidget {
  const ResolveIncidentSheet({super.key, required this.description});

  /// What was reported, in sight while it is being closed.
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
          Text(context.l10n.incidentCloseTitle, style: text.titleMedium),
          const SizedBox(height: 8),
          // The words of whoever reported it, quoted: closing without rereading
          // them is how the wrong one gets closed.
          Text(context.l10n.quoted(widget.description), style: text.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: context.l10n.incidentOutcomeLabel,
              errorText: empty ? context.l10n.incidentOutcomeRequired : null,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: Text(context.l10n.actionClose),
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
