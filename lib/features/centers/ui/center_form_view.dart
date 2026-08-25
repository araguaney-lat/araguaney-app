import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_create.dart';
import '../../../core/api/generated/models/center_out.dart';
import '../../../core/api/generated/models/center_update.dart';
import '../data/centers_providers.dart';
import '../data/centers_repository.dart';

/// Dar de alta un centro, o corregir uno.
///
/// **El alta existe porque aprobar una postulación crea un centro.** Antes de
/// la fase 22 este formulario no tenía ningún caso que empezara lejos de un
/// escritorio; ahora sí: quien acaba de aprobar puede necesitar arreglar un
/// dato que llegó mal en la postulación, en el momento en que lo ve.
///
/// **Solo el nombre es obligatorio**, porque es lo único que el contrato exige.
/// Añadir obligatorios propios sería una regla de negocio de este cliente, que
/// es justo lo que no lleva: si un centro necesita más para operar, eso lo
/// decide y lo dice el servidor.
class CenterFormView extends ConsumerStatefulWidget {
  const CenterFormView({super.key, this.existing});

  /// Nulo para un alta; el centro a corregir en otro caso.
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
        // La lista y la ficha se rehacen: un centro recién creado tiene que
        // estar donde se le va a buscar.
        ref.invalidate(centersProvider);
        ref.invalidate(centerRecordProvider(value.id));
        Navigator.of(context).pop(value);
      case CentersRefused(:final failure):
        // El mensaje del servidor entero: describe algo que quien lo escribe
        // puede corregir, como un correo mal formado.
        setState(() => _failure = failure.operatorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar centro' : 'Nuevo centro')),
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
                      ? field.label
                      : '${field.label} (opcional)',
                ),
                validator: field.required
                    ? (value) => (value == null || value.trim().isEmpty)
                          ? 'Escribe ${field.label.toLowerCase()}'
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
                  : Text(_isEdit ? 'Guardar' : 'Crear centro'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Los campos, en el mismo orden que el panel los pide.
///
/// Que coincidan importa poco por sí solo; lo que importa es que quien haya
/// dado de alta un centro en la web reconozca el formulario sin releerlo.
enum _CenterField {
  name('name', 'Nombre', required: true),
  legalName('legal_name', 'Razón social'),
  taxId('tax_id', 'Identificación fiscal'),
  address('address', 'Dirección'),
  countryCode(
    'country_code',
    'País',
    capitalization: TextCapitalization.characters,
  ),
  stateName('state_name', 'Estado o provincia'),
  contactName('contact_name', 'Nombre del contacto'),
  contactEmail(
    'contact_email',
    'Correo del contacto',
    keyboard: TextInputType.emailAddress,
  ),
  contactPhone(
    'contact_phone',
    'Teléfono del contacto',
    keyboard: TextInputType.phone,
  );

  const _CenterField(
    this.key,
    this.label, {
    this.required = false,
    this.keyboard = TextInputType.text,
    this.capitalization = TextCapitalization.sentences,
  });

  final String key;
  final String label;
  final bool required;
  final TextInputType keyboard;
  final TextCapitalization capitalization;
}
