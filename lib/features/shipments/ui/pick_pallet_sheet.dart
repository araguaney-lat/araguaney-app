import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/pallet_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../../core/ui/status_labels.dart';
import '../../pallets/data/pallets_providers.dart';

/// Which pallet goes into the shipment.
///
/// Only the **closed** ones are offered: an open pallet still takes boxes, and
/// putting it into a shipment would freeze it behind the back of whoever is
/// building it. The server would refuse it anyway; filtering here avoids
/// offering something that can only end in an error.
class PickPalletSheet extends ConsumerWidget {
  const PickPalletSheet({super.key, required this.alreadyIn});

  /// The ones already in this shipment, so they are not offered twice.
  final Set<String> alreadyIn;

  static Future<PalletOut?> show(
    BuildContext context, {
    required Set<String> alreadyIn,
  }) => showModalBottomSheet<PalletOut>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PickPalletSheet(alreadyIn: alreadyIn),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallets = ref.watch(palletsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, sheetBottomInset(context, base: 8)),
      child: switch (pallets) {
        AsyncData(:final value) => _List(
          pallets: value
              .where((p) => p.status == 'CLOSED' && !alreadyIn.contains(p.id))
              .toList(),
        ),
        AsyncError() => _Note(context.l10n.palletsUnavailable),
        _ => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.pallets});

  final List<PalletOut> pallets;

  @override
  Widget build(BuildContext context) {
    if (pallets.isEmpty) {
      return _Note(context.l10n.noClosedPallets);
    }

    return ListView(
      shrinkWrap: true,
      children: [
        for (final pallet in pallets)
          ListTile(
            title: Text(pallet.code),
            subtitle: Text(
              [
                palletStatusLabel(context.l10n, pallet.status),
                if (pallet.closedAt case final closed?)
                  context.l10n.palletClosedOn(formatShortDate(closed)),
                if (pallet.heightCm case final height?) '$height cm',
                if (pallet.grossWeightKg case final weight?) '$weight kg',
              ].join(' · '),
            ),
            onTap: () => Navigator.of(context).pop(pallet),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Text(text, textAlign: TextAlign.center),
  );
}
