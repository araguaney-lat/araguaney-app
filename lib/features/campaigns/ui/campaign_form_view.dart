import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/campaign_create.dart';
import '../../../core/api/generated/models/campaign_out.dart';
import '../../../core/api/generated/models/campaign_update.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../data/campaigns_providers.dart';
import '../data/campaigns_repository.dart';

/// Abrir una campaña, o corregirla.
///
/// **Solo administración nacional.** Crear y editar exigen ese rol, así que el
/// botón no existe para los demás en vez de existir y responder 403.
///
/// Obligatorio va lo único que el contrato exige, el nombre. Los centros que
/// participan (`center_ids`) no se eligen desde aquí: es una lista larga y una
/// decisión de escritorio, y el servidor acepta crearla sin ellos.
class CampaignFormView extends ConsumerStatefulWidget {
  const CampaignFormView({super.key, this.existing});

  final CampaignOut? existing;

  static Route<CampaignOut> route({CampaignOut? existing}) =>
      MaterialPageRoute<CampaignOut>(
        builder: (_) => CampaignFormView(existing: existing),
      );

  @override
  ConsumerState<CampaignFormView> createState() => _CampaignFormViewState();
}

class _CampaignFormViewState extends ConsumerState<CampaignFormView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();
  final _goal = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  String? _failure;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing case final campaign?) {
      _name.text = campaign.name;
      _description.text = campaign.description ?? '';
      _origin.text = campaign.originCountry ?? '';
      _destination.text = campaign.destinationCountry ?? '';
      _goal.text = campaign.weightGoalKg ?? '';
      _start = campaign.startDate;
      _end = campaign.endDate;
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _origin,
      _destination,
      _goal,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (chosen == null) return;
    setState(() => start ? _start = chosen : _end = chosen);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failure = null;
    });

    final repository = ref.read(campaignsRepositoryProvider);
    final outcome = _isEdit
        ? await repository.update(
            widget.existing!.id,
            CampaignUpdate(
              name: _name.text.trim(),
              description: _text(_description),
              originCountry: _text(_origin),
              destinationCountry: _text(_destination),
              weightGoalKg: _text(_goal),
              startDate: _start,
              endDate: _end,
            ),
          )
        : await repository.create(
            CampaignCreate(
              name: _name.text.trim(),
              description: _text(_description),
              originCountry: _text(_origin),
              destinationCountry: _text(_destination),
              startDate: _start,
              endDate: _end,
            ),
          );

    if (!mounted) return;
    setState(() => _saving = false);

    switch (outcome) {
      case CampaignRead(:final value):
        Navigator.of(context).pop(value);
      case CampaignRefused(:final failure):
        setState(() => _failure = failure.operatorMessage(context.l10n));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _isEdit
            ? context.l10n.campaignEditTitle
            : context.l10n.campaignNewTitle,
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: context.l10n.campaignNameLabel,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.fieldRequiredGeneric
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.optionalField(
                context.l10n.campaignPurposeLabel,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: context.l10n.campaignStartsLabel,
            value: _start,
            onPick: () => _pickDate(start: true),
          ),
          _DateField(
            label: context.l10n.campaignEndsLabel,
            value: _end,
            onPick: () => _pickDate(start: false),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _origin,
            decoration: InputDecoration(
              labelText: context.l10n.optionalField(
                context.l10n.campaignOriginLabel,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _destination,
            decoration: InputDecoration(
              labelText: context.l10n.optionalField(
                context.l10n.campaignDestinationLabel,
              ),
            ),
          ),
          // La meta solo se puede corregir: `CampaignCreate` no la lleva, y
          // ofrecer un campo que el alta descarta sería mentir sobre lo que se
          // está guardando.
          if (_isEdit) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _goal,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.optionalField(
                  context.l10n.campaignGoalLabel,
                ),
              ),
            ),
          ],
          if (_failure case final message?) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEdit
                        ? context.l10n.actionSave
                        : context.l10n.campaignCreateAction,
                  ),
          ),
        ],
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(
      value == null ? context.l10n.expiryNone : formatShortDate(value!),
    ),
    trailing: const Icon(Icons.event),
    onTap: onPick,
  );
}
