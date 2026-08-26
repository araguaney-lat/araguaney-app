import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';

/// Opening a request: a subject and a sentence.
///
/// **The form asks for words, not for quantities.** That is what makes this
/// worth doing from a phone: whoever knows what is missing is standing in the
/// warehouse, and «nos quedamos sin suero» typed with one thumb is a lower
/// barrier than a form of products and units. Turning that sentence into
/// categories is the server's job, and it does it afterwards.
class NewRequestSheet extends StatefulWidget {
  const NewRequestSheet({super.key});

  static Future<({String title, String description})?> show(
    BuildContext context,
  ) => showModalBottomSheet<({String title, String description})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const NewRequestSheet(),
  );

  @override
  State<NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<NewRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((title: _title.text.trim(), description: _description.text.trim()));
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
            context.l10n.requestNewTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.l10n.requestSubjectLabel,
              hintText: context.l10n.requestSubjectHint,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.requestSubjectRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 4,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.l10n.requestDescriptionLabel,
              helperText: context.l10n.requestDescriptionHint,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.requestDescriptionRequired
                : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submit,
              child: Text(context.l10n.requestCreateAction),
            ),
          ),
        ],
      ),
    ),
  );
}
