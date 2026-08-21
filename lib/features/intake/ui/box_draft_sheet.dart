import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/db/app_database.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../domain/box_draft_input.dart';
import 'product_picker_sheet.dart';

/// Alta y edición de **una** caja.
///
/// Una caja lleva un producto, un lote y una caducidad. No es una regla que
/// esta pantalla imponga: es la forma que tiene una caja en el contrato, y por
/// eso aquí no hay dónde escribir un segundo producto. Quien recibe dos cosas
/// distintas agrega dos cajas.
class BoxDraftSheet extends StatefulWidget {
  const BoxDraftSheet({super.key, this.initial});

  final BoxDraftInput? initial;

  static Future<BoxDraftInput?> show(
    BuildContext context, {
    BoxDraftInput? initial,
  }) => showModalBottomSheet<BoxDraftInput>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BoxDraftSheet(initial: initial),
  );

  @override
  State<BoxDraftSheet> createState() => _BoxDraftSheetState();
}

class _BoxDraftSheetState extends State<BoxDraftSheet> {
  final _formKey = GlobalKey<FormState>();

  late ProductTypeRow? _product = widget.initial?.productType;
  late final _quantity = TextEditingController(
    text: widget.initial?.quantity.toString() ?? '',
  );
  late final _unit = TextEditingController(
    text: widget.initial?.unit ?? widget.initial?.productType.defaultUnit ?? '',
  );
  late final _batch = TextEditingController(text: widget.initial?.batch ?? '');
  late final _weight = TextEditingController(
    text: widget.initial?.weightKg ?? '',
  );
  late DateTime? _expiry = widget.initial?.expiryDate;

  @override
  void dispose() {
    _quantity.dispose();
    _unit.dispose();
    _batch.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final product = await ProductPickerSheet.show(context);
    if (product == null) return;

    setState(() {
      _product = product;
      // La unidad por defecto del catálogo ahorra un campo en el caso normal,
      // sin impedir corregirla cuando la caja trae otra cosa.
      if (_unit.text.isEmpty && product.defaultUnit != null) {
        _unit.text = product.defaultUnit!;
      }
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  void _save() {
    if (_product == null || !_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      BoxDraftInput(
        productType: _product!,
        quantity: int.parse(_quantity.text),
        unit: _unit.text.trim(),
        batch: _emptyToNull(_batch.text),
        expiryDate: _expiry,
        weightKg: _emptyToNull(_weight.text),
        code: widget.initial?.code,
        // El del catálogo, que es el del envase que se escaneó o el del
        // producto elegido a mano. El contrato lo acepta y hasta ahora nadie
        // lo escribía.
        gtin: _product!.gtin ?? widget.initial?.gtin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.9,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Agregar caja' : 'Editar caja'),
      ),
      // Guardar confirma, y confirmar es dorado. Estaba en azul arriba, que es
      // el color de navegar: la misma hoja enseñaba lo contrario de lo que
      // enseña la pantalla que la abre.
      //
      // La barra inferior de un `Scaffold` no sube con el teclado ni esquiva la
      // barra de navegación del sistema. Lo último que se escribe antes de
      // guardar es la cantidad, así que sin esto el botón queda tapado justo
      // cuando hace falta —y en un teléfono de tres botones, tapado siempre.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, sheetBottomInset(context)),
        child: SizedBox(
          width: double.infinity,
          child: ConfirmButton(label: 'Guardar', onPressed: _save),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_product case final product?)
              Card(
                child: Column(
                  children: [
                    RecordField(label: 'Producto', value: product.displayName),
                    OverflowBar(
                      children: [
                        TextButton(
                          onPressed: _pickProduct,
                          child: const Text('Cambiar'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              FilledButton.tonalIcon(
                onPressed: _pickProduct,
                icon: const Icon(Icons.search),
                label: const Text('Elegir producto'),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantity,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Escribe cuántas unidades trae la caja';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unit,
              decoration: const InputDecoration(
                labelText: 'Unidad',
                helperText: 'Cajas, frascos, sobres…',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Indica la unidad'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _batch,
              decoration: const InputDecoration(labelText: 'Lote (opcional)'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Caducidad'),
              subtitle: Text(
                _expiry == null ? 'Sin fecha' : formatShortDate(_expiry!),
              ),
              trailing: const Icon(Icons.event),
              onTap: _pickExpiry,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              decoration: const InputDecoration(
                labelText: 'Peso en kg (opcional)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Una caja lleva un solo producto, un lote y una caducidad. Si '
              'recibiste dos cosas distintas, agrega dos cajas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
