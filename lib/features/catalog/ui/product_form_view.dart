import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/barcode_prefill.dart';
import '../../../core/api/generated/models/product_type_create.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/api/generated/models/product_type_update.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../data/catalog_providers.dart';
import '../data/catalog_repository.dart';

/// Dar de alta un producto, o corregirlo.
///
/// **Solo lo ve quien administra a nivel nacional**, porque es lo único que el
/// servidor acepta: `product_type.py` exige ese rol para crear y para editar.
/// Quien captura llega hasta aquí por otro camino —pedirlo— y no por un
/// formulario que iba a responder 403.
///
/// Obligatorios son los dos que el contrato exige, nombre y categoría. Añadir
/// más sería inventar una regla de negocio en el cliente.
class ProductFormView extends ConsumerStatefulWidget {
  const ProductFormView({super.key, this.existing, this.prefill});

  /// Nulo para un alta; el producto a corregir en otro caso.
  final ProductTypeOut? existing;

  /// Lo que Open Food Facts supo del envase escaneado.
  ///
  /// Llega como borrador y nada más: son datos de un tercero, y quien los
  /// confirma es quien tiene el envase delante.
  final BarcodePrefill? prefill;

  static Route<ProductTypeOut> route({
    ProductTypeOut? existing,
    BarcodePrefill? prefill,
  }) => MaterialPageRoute<ProductTypeOut>(
    builder: (_) => ProductFormView(existing: existing, prefill: prefill),
  );

  @override
  ConsumerState<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends ConsumerState<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _form = TextEditingController();
  final _strength = TextEditingController();
  final _unit = TextEditingController();
  final _inn = TextEditingController();
  final _gtin = TextEditingController();
  final _unitWeight = TextEditingController();
  final _shelfLife = TextEditingController();

  String _category = productCategories.first;
  bool _controlled = false;
  bool _saving = false;
  String? _failure;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing case final product?) {
      _name.text = product.displayName;
      _brand.text = product.brand ?? '';
      _form.text = product.form ?? '';
      _strength.text = product.strength ?? '';
      _unit.text = product.defaultUnit ?? '';
      _inn.text = product.innName ?? '';
      _gtin.text = product.gtin ?? '';
      _unitWeight.text = product.unitWeightKg ?? '';
      _shelfLife.text = product.minShelfLifeDays?.toString() ?? '';
      _controlled = product.isControlled;
      _category = _knownCategory(product.category);
    } else if (widget.prefill case final prefill?) {
      _name.text = prefill.displayName;
      _brand.text = prefill.brand ?? '';
      _gtin.text = prefill.gtin;
      _category = _knownCategory(prefill.category);
    }
  }

  /// Una categoría que esta versión no conoce no puede perderse en un
  /// desplegable: el contrato es aditivo y el servidor puede haber añadido una.
  String _knownCategory(String category) =>
      productCategories.contains(category) ? category : productCategories.first;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _brand,
      _form,
      _strength,
      _unit,
      _inn,
      _gtin,
      _unitWeight,
      _shelfLife,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failure = null;
    });

    final repository = ref.read(catalogRepositoryProvider);
    final outcome = _isEdit
        ? await repository.update(
            widget.existing!.id,
            ProductTypeUpdate(
              displayName: _name.text.trim(),
              category: _category,
              brand: _text(_brand),
              form: _text(_form),
              strength: _text(_strength),
              defaultUnit: _text(_unit),
              innName: _text(_inn),
              gtin: _text(_gtin),
              unitWeightKg: _text(_unitWeight),
              minShelfLifeDays: int.tryParse(_shelfLife.text.trim()),
              isControlled: _controlled,
            ),
          )
        : await repository.create(
            ProductTypeCreate(
              displayName: _name.text.trim(),
              category: _category,
              brand: _text(_brand),
              form: _text(_form),
              strength: _text(_strength),
              defaultUnit: _text(_unit),
              innName: _text(_inn),
              gtin: _text(_gtin),
              unitWeightKg: _text(_unitWeight),
              minShelfLifeDays: int.tryParse(_shelfLife.text.trim()),
              isControlled: _controlled,
            ),
          );

    if (!mounted) return;
    setState(() => _saving = false);

    switch (outcome) {
      case CatalogDone(:final value):
        Navigator.of(context).pop(value);
      case CatalogRefused(:final failure):
        setState(() => _failure = failure.operatorMessage(context.l10n));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _isEdit ? context.l10n.productEditTitle : context.l10n.productNewTitle,
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
            decoration: InputDecoration(labelText: context.l10n.productLabel),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? context.l10n.fieldRequiredGeneric
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
              labelText: context.l10n.categoryFieldLabel,
            ),
            items: [
              for (final category in productCategories)
                DropdownMenuItem(
                  value: category,
                  child: Text(categoryLabel(context.l10n, category)),
                ),
            ],
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          _field(_brand, context.l10n.brandLabel),
          _field(_form, context.l10n.formLabel),
          _field(_strength, context.l10n.strengthLabel),
          _field(_unit, context.l10n.unitLabel),
          _field(_inn, context.l10n.innLabel),
          _field(_gtin, context.l10n.gtinLabel, keyboard: TextInputType.number),
          _field(
            _unitWeight,
            context.l10n.unitWeightLabel,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          _field(
            _shelfLife,
            context.l10n.minShelfLifeLabel,
            keyboard: TextInputType.number,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _controlled,
            onChanged: (value) => setState(() => _controlled = value),
            title: Text(context.l10n.controlledLabel),
            subtitle: Text(context.l10n.controlledExplanation),
          ),
          if (_failure case final message?) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
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
                        : context.l10n.productCreateAction,
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: context.l10n.optionalField(label)),
    ),
  );
}
