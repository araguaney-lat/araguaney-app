import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../domain/box_draft_input.dart';
import 'product_picker_sheet.dart';

/// Adding and editing **one** box.
///
/// A box carries one product, one batch and one expiry date. It is not a rule
/// this screen imposes: it is the shape a box has in the contract, and that is
/// why there is nowhere here to write a second product. Whoever receives two
/// different things adds two boxes.
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
      // The catalogue's default unit saves a field in the normal case,
      // without stopping it being corrected when the box carries something
      // else.
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
        // The catalogue's, which is that of the package that was scanned or of
        // the product chosen by hand. The contract accepts it and until now
        // nobody was writing it.
        gtin: _product!.gtin ?? widget.initial?.gtin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: 0.9,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null
              ? context.l10n.boxDraftAddTitle
              : context.l10n.boxDraftEditTitle,
        ),
      ),
      // Saving confirms, and confirming is gold. It used to be blue up top,
      // which is the colour of navigating: the same sheet was teaching the
      // opposite of what the screen that opens it teaches.
      //
      // A `Scaffold`'s bottom bar does not rise with the keyboard nor dodge the
      // system navigation bar. The last thing written before saving is the
      // quantity, so without this the button ends up covered exactly when it is
      // needed — and on a three-button phone, covered always.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, sheetBottomInset(context)),
        child: SizedBox(
          width: double.infinity,
          child: ConfirmButton(
            label: context.l10n.actionSave,
            onPressed: _save,
          ),
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
                    RecordField(
                      label: context.l10n.productLabel,
                      value: product.displayName,
                    ),
                    OverflowBar(
                      children: [
                        TextButton(
                          onPressed: _pickProduct,
                          child: Text(context.l10n.changeAction),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              // Outlined and not tonal: this opens a search, it confirms
              // nothing, and ever since the tonal button got its own colour
              // back — the soft gold — it would have said «confirmar» on a
              // screen where what gets confirmed is further down.
              OutlinedButton.icon(
                onPressed: _pickProduct,
                icon: const Icon(Icons.search),
                label: Text(context.l10n.productPickAction),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantity,
              decoration: InputDecoration(
                labelText: context.l10n.quantityLabel,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed < 1) {
                  return context.l10n.quantityRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unit,
              decoration: InputDecoration(
                labelText: context.l10n.unitLabel,
                helperText: context.l10n.unitHint,
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? context.l10n.unitRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _batch,
              decoration: InputDecoration(
                labelText: context.l10n.batchOptionalLabel,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.expiryLabel),
              subtitle: Text(
                _expiry == null
                    ? context.l10n.expiryNone
                    : formatShortDate(_expiry!),
              ),
              trailing: const Icon(Icons.event),
              onTap: _pickExpiry,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weight,
              decoration: InputDecoration(
                labelText: context.l10n.weightKgOptionalLabel,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.boxHoldsOneProduct,
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
