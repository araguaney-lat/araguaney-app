import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/api/generated/models/reception_exception_in.dart';
import '../../../core/api/generated/models/reception_pallet_weight_in.dart';
import '../../../core/api/generated/models/shipment_detail_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/status_labels.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../data/shipments_providers.dart';
import '../data/shipments_repository.dart';

/// Registrar qué llegó, caja por caja.
///
/// **Marcar es la excepción.** El servidor da por recibido todo lo que no viene
/// marcado, así que un envío que llegó entero es un solo botón y lo que viaja
/// es exactamente lo que alguien miró y decidió. Es el mismo reparto que la
/// recepción de una donación anunciada, y por la misma razón.
///
/// Se hace **una sola vez**: corregir una recepción es una incidencia con su
/// nota, no reescribir lo que ya viajó a un informe. La pantalla lo dice antes
/// de enviar, no después.
///
/// El peso de cada tarima es opcional y sirve para dos cosas: queda en el
/// documento, y el servidor lo compara con lo que pesaba al cerrarse. Si
/// difieren de más abre una incidencia — cuánto es «de más» es criterio suyo y
/// no se enseña aquí.
class RegisterReceptionView extends ConsumerStatefulWidget {
  const RegisterReceptionView({super.key, required this.shipment});

  final ShipmentDetailOut shipment;

  static Route<bool> route(ShipmentDetailOut shipment) =>
      MaterialPageRoute<bool>(
        builder: (_) => RegisterReceptionView(shipment: shipment),
      );

  @override
  ConsumerState<RegisterReceptionView> createState() =>
      _RegisterReceptionViewState();
}

class _RegisterReceptionViewState extends ConsumerState<RegisterReceptionView> {
  final _consignee = TextEditingController();
  final _notes = TextEditingController();

  /// Solo las cajas que no llegaron bien, por identificador.
  final _exceptions = <String, String>{};

  /// Lo que pesó cada tarima al llegar, tal como se teclea.
  final _weights = <String, TextEditingController>{};

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    for (final pallet in widget.shipment.pallets) {
      _weights[pallet.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _consignee.dispose();
    _notes.dispose();
    for (final controller in _weights.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggle(String boxId, String outcome) => setState(() {
    if (_exceptions[boxId] == outcome) {
      _exceptions.remove(boxId);
    } else {
      _exceptions[boxId] = outcome;
    }
  });

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.receptionConfirmTitle),
        content: Text(context.l10n.receptionConfirmExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.receptionRegisterAction),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;

    setState(() => _sending = true);
    final outcome = await ref
        .read(shipmentsRepositoryProvider)
        .registerReception(
          shipmentId: widget.shipment.id,
          exceptions: [
            for (final entry in _exceptions.entries)
              ReceptionExceptionIn(boxId: entry.key, outcome: entry.value),
          ],
          palletWeights: [
            for (final entry in _weights.entries)
              if (entry.value.text.trim().isNotEmpty)
                ReceptionPalletWeightIn(
                  palletId: entry.key,
                  grossWeightKg: entry.value.text.trim(),
                ),
          ],
          consigneeName: _consignee.text.trim().isEmpty
              ? null
              : _consignee.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (outcome) {
      case ShipmentDone():
        Navigator.of(context).pop(true);
      // El motivo es del servidor: que el envío no está entregado, que ya tiene
      // recepción, que una caja no es de este envío.
      case ShipmentRefused(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failure.operatorMessage(context.l10n))),
          );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.receptionRegisterTitle)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          context.l10n.receptionExplanation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _consignee,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.l10n.optionalField(
              context.l10n.consigneeNameLabel,
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (final pallet in widget.shipment.pallets)
          _Pallet(
            pallet: pallet,
            weight: _weights[pallet.id]!,
            exceptions: _exceptions,
            onToggle: _toggle,
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.optionalField(context.l10n.notesLabel),
          ),
        ),
        const SizedBox(height: 20),
        ConfirmButton(
          label: context.l10n.receptionRegisterAction,
          onPressed: _sending ? null : _submit,
        ),
      ],
    ),
  );
}

class _Pallet extends StatelessWidget {
  const _Pallet({
    required this.pallet,
    required this.weight,
    required this.exceptions,
    required this.onToggle,
  });

  final PalletDetailOut pallet;
  final TextEditingController weight;
  final Map<String, String> exceptions;
  final void Function(String boxId, String outcome) onToggle;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pallet.code, style: Theme.of(context).textTheme.titleSmall),
          TextField(
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.optionalField(
                context.l10n.receptionArrivedWeightLabel,
              ),
              helperText: context.l10n.receptionWeightHelper,
            ),
          ),
          const SizedBox(height: 8),
          for (final box in pallet.boxes)
            _Box(
              code: box.code,
              outcome: exceptions[box.id],
              onToggle: (outcome) => onToggle(box.id, outcome),
            ),
        ],
      ),
    ),
  );
}

class _Box extends StatelessWidget {
  const _Box({
    required this.code,
    required this.outcome,
    required this.onToggle,
  });

  final String code;
  final String? outcome;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code, style: Theme.of(context).textTheme.bodyMedium),
          Wrap(
            spacing: 6,
            children: [
              for (final option in ReceptionOutcome.exceptions)
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(receptionOutcomeLabel(context.l10n, option)),
                  selected: outcome == option,
                  selectedColor: palette.alertFill,
                  onSelected: (_) => onToggle(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
