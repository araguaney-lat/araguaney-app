import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_create.dart';
import '../../../core/api/generated/models/center_out.dart';
import '../../../core/api/generated/models/center_update.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../data/centers_providers.dart';
import '../data/centers_repository.dart';

/// Adding a centre, or correcting one.
///
/// **Adding exists because approving an application creates a centre.** Before
/// phase 22 this form had no case that started far from a desk; now it does:
/// whoever has just approved may need to fix a detail that arrived wrong in the
/// application, at the moment they see it.
///
/// **Only the name is required**, because it is all the contract requires.
/// Adding required fields of our own would be a business rule of this client,
/// which is exactly what it does not carry: if a centre needs more in order to
/// operate, the server decides and says so.
class CenterFormView extends ConsumerStatefulWidget {
  const CenterFormView({super.key, this.existing});

  /// Null when adding; the centre to correct otherwise.
  final CenterOut? existing;

  static Route<CenterOut> route({CenterOut? existing}) =>
      MaterialPageRoute<CenterOut>(
        builder: (_) => CenterFormView(existing: existing),
      );

  @override
  ConsumerState<CenterFormView> createState() => _CenterFormViewState();
}

class _CenterFormViewState extends ConsumerState<CenterFormView> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields = {
    for (final name in _CenterField.values.map((f) => f.key))
      name: TextEditingController(),
  };
  bool _saving = false;
  String? _failure;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final center = widget.existing;
    if (center == null) return;
    _fields[_CenterField.name.key]!.text = center.name;
    _fields[_CenterField.legalName.key]!.text = center.legalName ?? '';
    _fields[_CenterField.taxId.key]!.text = center.taxId ?? '';
    _fields[_CenterField.address.key]!.text = center.address ?? '';
    _fields[_CenterField.countryCode.key]!.text = center.countryCode ?? '';
    _fields[_CenterField.stateName.key]!.text = center.stateName ?? '';
    _fields[_CenterField.contactName.key]!.text = center.contactName ?? '';
    _fields[_CenterField.contactEmail.key]!.text = center.contactEmail ?? '';
    _fields[_CenterField.contactPhone.key]!.text = center.contactPhone ?? '';
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _value(_CenterField field) {
    final text = _fields[field.key]!.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _failure = null;
    });

    final repository = ref.read(centersRepositoryProvider);
    final center = widget.existing;
    final outcome = center == null
        ? await repository.create(
            CenterCreate(
              name: _value(_CenterField.name)!,
              legalName: _value(_CenterField.legalName),
              taxId: _value(_CenterField.taxId),
              address: _value(_CenterField.address),
              countryCode: _value(_CenterField.countryCode),
              stateName: _value(_CenterField.stateName),
              contactName: _value(_CenterField.contactName),
              contactEmail: _value(_CenterField.contactEmail),
              contactPhone: _value(_CenterField.contactPhone),
            ),
          )
        : await repository.update(
            center.id,
            CenterUpdate(
              name: _value(_CenterField.name),
              legalName: _value(_CenterField.legalName),
              taxId: _value(_CenterField.taxId),
              address: _value(_CenterField.address),
              countryCode: _value(_CenterField.countryCode),
              stateName: _value(_CenterField.stateName),
              contactName: _value(_CenterField.contactName),
              contactEmail: _value(_CenterField.contactEmail),
              contactPhone: _value(_CenterField.contactPhone),
            ),
          );

    if (!mounted) return;
    setState(() => _saving = false);

    switch (outcome) {
      case CentersRead(:final value):
        // The list and the record are rebuilt: a freshly created centre has to
        // be where somebody is going to look for it.
        ref.invalidate(centersProvider);
        ref.invalidate(centerRecordProvider(value.id));
        Navigator.of(context).pop(value);
      case CentersRefused(:final failure):
        // The server's whole message: it describes something whoever wrote it
        // can correct, like a malformed email address.
        setState(() => _failure = failure.operatorMessage(context.l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? context.l10n.centerEditTitle : context.l10n.centerNewTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final field in _CenterField.values) ...[
              TextFormField(
                controller: _fields[field.key],
                keyboardType: field.keyboard,
                textCapitalization: field.capitalization,
                autocorrect: field.keyboard == TextInputType.text,
                decoration: InputDecoration(
                  labelText: field.required
                      ? field.label(context.l10n)
                      : context.l10n.optionalField(field.label(context.l10n)),
                ),
                validator: field.required
                    ? (value) => (value == null || value.trim().isEmpty)
                          ? context.l10n.fieldRequired(
                              field.label(context.l10n).toLowerCase(),
                            )
                          : null
                    : null,
              ),
              const SizedBox(height: 16),
            ],
            if (_failure case final message?) ...[
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
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
                          : context.l10n.centerCreateAction,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The fields, in the same order the panel asks for them.
///
/// That they match matters little in itself; what matters is that whoever has
/// added a centre on the web recognises the form without rereading it.
enum _CenterField {
  name('name', required: true),
  legalName('legal_name'),
  taxId('tax_id'),
  address('address'),
  countryCode('country_code', capitalization: TextCapitalization.characters),
  stateName('state_name'),
  contactName('contact_name'),
  contactEmail('contact_email', keyboard: TextInputType.emailAddress),
  contactPhone('contact_phone', keyboard: TextInputType.phone);

  const _CenterField(
    this.key, {
    this.required = false,
    this.keyboard = TextInputType.text,
    this.capitalization = TextCapitalization.sentences,
  });

  final String key;
  final bool required;
  final TextInputType keyboard;
  final TextCapitalization capitalization;

  /// The label is resolved when drawing and not in the constant: a constant
  /// cannot be a call, and the language is only known once there is a context.
  String label(AppLocalizations l10n) => switch (this) {
    _CenterField.name => l10n.nameLabel,
    _CenterField.legalName => l10n.centerLegalNameLabel,
    _CenterField.taxId => l10n.taxIdLabel,
    _CenterField.address => l10n.addressLabel,
    _CenterField.countryCode => l10n.countryLabel,
    _CenterField.stateName => l10n.stateLabel,
    _CenterField.contactName => l10n.contactNameLabel,
    _CenterField.contactEmail => l10n.contactEmailLabel,
    _CenterField.contactPhone => l10n.contactPhoneLabel,
  };
}
