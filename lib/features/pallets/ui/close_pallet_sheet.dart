import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';

/// Peso bruto y altura con los que se cierra una tarima.
///
/// Los dos son opcionales en el contrato y aquí también: una báscula rota no
/// puede impedir cerrar una tarima que ya está armada. Lo que el servidor haga
/// con la diferencia entre este peso y la suma de las cajas es asunto suyo;
/// aquí no se calcula ni se avisa de nada, porque el criterio de cuándo esa
/// diferencia importa vive allá.
class ClosePalletSheet extends StatefulWidget {
  const ClosePalletSheet({super.key});

  static Future<({String? grossWeightKg, int? heightCm})?> show(
    BuildContext context,
  ) => showModalBottomSheet<({String? grossWeightKg, int? heightCm})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const ClosePalletSheet(),
  );

  @override
  State<ClosePalletSheet> createState() => _ClosePalletSheetState();
}

class _ClosePalletSheetState extends State<ClosePalletSheet> {
  final _weight = TextEditingController();
  final _height = TextEditingController();

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _close() {
    final weight = _weight.text.trim();
    final height = int.tryParse(_height.text.trim());

    Navigator.of(
      context,
    ).pop((grossWeightKg: weight.isEmpty ? null : weight, heightCm: height));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: sheetBottomInset(context),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.palletsCerrarTarima,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.palletsUnaTarimaCerradaYaNo,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weight,
          decoration: InputDecoration(
            labelText: context.l10n.palletsPesoBrutoEnKgOpcional,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _height,
          decoration: InputDecoration(
            labelText: context.l10n.palletsAlturaEnCmOpcional,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _close,
            child: Text(context.l10n.palletsCerrarTarima),
          ),
        ),
      ],
    ),
  );
}
