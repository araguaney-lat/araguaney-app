import 'package:flutter/material.dart';

import '../../../core/api/generated/models/shipment_create.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/sheet_insets.dart';

/// Abrir un envío.
///
/// Solo el destino es obligatorio, y es el contrato quien lo decide: un envío
/// existe para llevar algo a alguna parte, y todo lo demás —transportista,
/// referencia, notas— puede aparecer después, mientras el envío sigue abierto.
class CreateShipmentSheet extends StatefulWidget {
  const CreateShipmentSheet({super.key});

  static Future<ShipmentCreate?> show(BuildContext context) =>
      showModalBottomSheet<ShipmentCreate>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const CreateShipmentSheet(),
      );

  @override
  State<CreateShipmentSheet> createState() => _CreateShipmentSheetState();
}

class _CreateShipmentSheetState extends State<CreateShipmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _destination = TextEditingController(text: 'Venezuela');
  final _carrier = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _destination.dispose();
    _carrier.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ShipmentCreate(
        destination: _destination.text.trim(),
        carrier: _empty(_carrier.text),
        reference: _empty(_reference.text),
        notes: _empty(_notes.text),
      ),
    );
  }

  static String? _empty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, sheetBottomInset(context)),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.shipmentNewTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _destination,
            decoration: InputDecoration(
              labelText: context.l10n.destinationLabel,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.destinationRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _carrier,
            decoration: InputDecoration(
              labelText: context.l10n.carrierOptionalLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reference,
            decoration: InputDecoration(
              labelText: context.l10n.referenceOptionalLabel,
              helperText: context.l10n.shipmentReferenceHint,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.notesOptionalLabel,
            ),
          ),
          const SizedBox(height: 20),
          ConfirmButton(
            label: context.l10n.shipmentOpenAction,
            onPressed: _save,
          ),
        ],
      ),
    ),
  );
}
