import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../intake/data/intake_providers.dart';

/// Abrir un hilo de campaña.
///
/// Solo hilos de campaña, que los lee cualquiera que participe en ella. Un hilo
/// privado exige elegir destinatarios de entre quienes participan, y esa
/// selección es trabajo de escritorio; desde un teléfono lo que se hace es
/// avisar de algo a quien esté en la campaña.
class NewThreadSheet extends ConsumerStatefulWidget {
  const NewThreadSheet({super.key});

  static Future<({String campaignId, String title, String body})?> show(
    BuildContext context,
  ) => showModalBottomSheet<({String campaignId, String title, String body})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const NewThreadSheet(),
  );

  @override
  ConsumerState<NewThreadSheet> createState() => _NewThreadSheetState();
}

class _NewThreadSheetState extends ConsumerState<NewThreadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _campaignId;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _submit() {
    if (_campaignId == null || !_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      campaignId: _campaignId!,
      title: _title.text.trim(),
      body: _body.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(myCampaignsProvider).valueOrNull ?? [];

    return Padding(
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
              context.l10n.threadNewTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.threadAudienceHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (campaigns.isEmpty)
              Text(context.l10n.noCampaignsForThread)
            else
              DropdownButtonFormField<String>(
                initialValue: _campaignId,
                decoration: InputDecoration(
                  labelText: context.l10n.campaignLabel,
                ),
                items: [
                  for (final campaign in campaigns)
                    DropdownMenuItem(
                      value: campaign.id,
                      child: Text(campaign.name),
                    ),
                ],
                onChanged: (value) => setState(() => _campaignId = value),
                validator: (value) =>
                    value == null ? 'Elige una campaña' : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: context.l10n.subjectLabel),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Escribe un asunto'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 4,
              decoration: InputDecoration(labelText: context.l10n.messageLabel),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Escribe el mensaje'
                  : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: campaigns.isEmpty ? null : _submit,
                child: Text(context.l10n.threadOpenAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
