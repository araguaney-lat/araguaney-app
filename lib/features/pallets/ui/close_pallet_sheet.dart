import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/sheet_insets.dart';

/// The gross weight and height a pallet is closed with.
///
/// Both are optional in the contract and optional here too: a broken scale
/// cannot stop a pallet that is already built from being closed. What the
/// server does with the difference between this weight and the sum of the boxes
/// is its own business; nothing is computed or warned about here, because the
/// judgement of when that difference matters lives over there.
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
          context.l10n.palletCloseTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.palletCloseWarning,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weight,
          decoration: InputDecoration(
            labelText: context.l10n.grossWeightKgOptionalLabel,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _height,
          decoration: InputDecoration(
            labelText: context.l10n.heightCmOptionalLabel,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _close,
            child: Text(context.l10n.palletCloseTitle),
          ),
        ),
      ],
    ),
  );
}
