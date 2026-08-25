import 'package:flutter/material.dart';

import '../../../core/api/generated/models/donor_input.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../domain/intake_draft.dart';

/// El donante que se identifica en el mostrador.
///
/// La casilla de los Términos se muestra siempre y **no bloquea aquí**: quién
/// tiene que aceptarlos es una regla del backend, que responde
/// `TERMS_NOT_ACCEPTED` cuando falta. Repetir esa condición en el cliente
/// significaría mantener dos versiones de ella, y la del servidor es la que
/// manda.
class DonorSheet extends StatefulWidget {
  const DonorSheet({super.key, this.initial, this.termsAccepted = false});

  final DonorInput? initial;
  final bool termsAccepted;

  static Future<({DonorInput donor, bool termsAccepted})?> show(
    BuildContext context, {
    DonorInput? initial,
    bool termsAccepted = false,
  }) => showModalBottomSheet<({DonorInput donor, bool termsAccepted})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DonorSheet(initial: initial, termsAccepted: termsAccepted),
  );

  @override
  State<DonorSheet> createState() => _DonorSheetState();
}

class _DonorSheetState extends State<DonorSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _type = widget.initial?.donorType ?? DonorType.natural;
  late final _firstName = TextEditingController(
    text: widget.initial?.firstName ?? '',
  );
  late final _lastName = TextEditingController(
    text: widget.initial?.lastName ?? '',
  );
  late final _legalName = TextEditingController(
    text: widget.initial?.legalName ?? '',
  );
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late bool _terms = widget.termsAccepted;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _legalName.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop((
      donor: DonorInput(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        donorType: _type,
        legalName: _emptyToNull(_legalName.text),
        email: _emptyToNull(_email.text),
        phone: _emptyToNull(_phone.text),
      ),
      termsAccepted: _terms,
    ));
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.9,
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.intakeIdentificarDonante),
        actions: [
          TextButton(onPressed: _save, child: Text(context.l10n.actionSave)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: DonorType.natural,
                  label: Text(context.l10n.intakePersona),
                ),
                ButtonSegment(
                  value: DonorType.legal,
                  label: Text(context.l10n.intakeEmpresa),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstName,
              decoration: InputDecoration(
                labelText: context.l10n.accountNombre,
              ),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: InputDecoration(
                labelText: context.l10n.intakeApellido,
              ),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            if (_type == DonorType.legal) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _legalName,
                decoration: InputDecoration(
                  labelText: context.l10n.centersRazonSocial,
                  helperText: context.l10n.intakeElNombreConElQue,
                ),
                textCapitalization: TextCapitalization.words,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                labelText: context.l10n.intakeCorreoOpcional,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: InputDecoration(
                labelText: context.l10n.intakeTelefonoOpcional,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _terms,
              onChanged: (value) => setState(() => _terms = value ?? false),
              title: Text(context.l10n.intakeAceptaLosTerminosDeDonacion),
              subtitle: Text(context.l10n.intakeQuienDonaANombreDe),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    ),
  );

  static String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Este campo hace falta' : null;

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
