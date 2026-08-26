import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_extension.dart';

import '../../../core/ui/sheet_insets.dart';

/// Rejecting an application, with its reason.
///
/// **What is written here is going to be read by whoever applied**, in an
/// email, outside the platform and probably with no more context than that
/// sentence. That is why the field is required — the server requires it too —
/// and why the screen says where it goes before anybody starts writing.
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
            context.l10n.applicationRejectTitle(widget.centerName),
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
              errorText: empty ? context.l10n.rejectReasonRequired : null,
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
