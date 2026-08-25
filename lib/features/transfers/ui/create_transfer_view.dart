import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/status_labels.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/data/centers_repository.dart';
import '../../scanning/domain/scanned_code.dart';
import '../../scanning/ui/continuous_scan_view.dart';
import '../data/transfers_providers.dart';
import '../data/transfers_repository.dart';
import 'transfer_detail_view.dart';

/// Proponer una transferencia a otro centro.
///
/// La aplicación sabía responder una transferencia —aprobarla, rechazarla,
/// despacharla, recibirla— y no sabía empezar una. Empezarla es la mitad que
/// arranca frente a un estante, mirando cajas que otro centro necesita más.
///
/// **Las cajas se eligen escaneándolas.** `TransferCreate` lleva `box_ids`: se
/// mueven bultos concretos, no una cantidad de un producto. Escanear es además
/// la única forma de elegir que no puede señalar una caja que no está en la
/// mano.
class CreateTransferView extends ConsumerStatefulWidget {
  const CreateTransferView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const CreateTransferView());

  @override
  ConsumerState<CreateTransferView> createState() => _CreateTransferViewState();
}

class _CreateTransferViewState extends ConsumerState<CreateTransferView> {
  final _notes = TextEditingController();
  final _boxes = <BoxRow>[];

  String? _destinationId;
  bool _sending = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// Por qué esta caja no puede ir, mirando lo que el servidor ya dijo de ella.
  ///
  /// **No es duplicar la regla del servidor: es leer el estado que él sirvió.**
  /// Y hace falta porque crear es una sola llamada con toda la lista dentro: una
  /// caja mala rechaza las veinte, y descubrirlo al final significaría volver a
  /// escanear desde cero. El servidor sigue decidiendo al crear.
  String? _refusalFor(BoxRow box) {
    final l10n = context.l10n;
    if (_boxes.any((chosen) => chosen.id == box.id)) {
      return l10n.transferBoxAlreadyChosen;
    }
    if (box.status != 'SEALED') {
      return l10n.transferBoxNotSealed(boxStatusLabel(l10n, box.status));
    }
    if (box.palletId != null) return l10n.transferBoxInPallet;
    return null;
  }

  Future<void> _scan() async {
    final l10n = context.l10n;
    final database = ref.read(appDatabaseProvider);

    await Navigator.of(context).push(
      ContinuousScanView.route(
        title: l10n.transferChooseBoxesTitle,
        hint: l10n.transferScanBoxesHint,
        onScanned: (payload) async {
          final scanned = parseScannedCode(payload);
          if (scanned is! BoxCode) {
            return ScanFeedback.rejected(l10n.scannedCodeIsNotABox);
          }

          final box = await database.boxesDao.findByCode(scanned.code);
          // Sin señal y sin la caja descargada no hay nada que decir de ella,
          // y meterla a ciegas es lo que hace que el servidor rechace la lista
          // entera al final.
          if (box == null) {
            return ScanFeedback.rejected(
              '${scanned.code} · ${l10n.transferBoxNotCached}',
            );
          }

          if (_refusalFor(box) case final reason?) {
            return ScanFeedback.rejected('${scanned.code} · $reason');
          }

          setState(() => _boxes.add(box));
          return ScanFeedback.accepted(
            l10n.transferBoxAdded(scanned.code, _boxes.length),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final origin = ref.read(actingCenterIdProvider);
    if (origin == null || _destinationId == null || _boxes.isEmpty) return;

    setState(() => _sending = true);
    final outcome = await ref
        .read(transfersRepositoryProvider)
        .create(
          fromCenterId: origin,
          toCenterId: _destinationId!,
          boxIds: _boxes.map((box) => box.id).toList(growable: false),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (outcome) {
      case TransferAdvanced(:final transfer):
        ref.invalidate(transfersProvider);
        await Navigator.of(
          context,
        ).pushReplacement(TransferDetailView.route(transfer.id));
      // El motivo es del servidor: que una caja no está sellada, que ya viaja
      // en otra transferencia, que no es del centro de origen.
      case TransferRefused(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failure.operatorMessage(context.l10n))),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin = ref.watch(actingCenterIdProvider);
    final centers = switch (ref.watch(centersProvider).valueOrNull) {
      CentersRead(:final value) =>
        value
            .where((center) => center.isActive && center.id != origin)
            .toList(),
      _ => const <CenterOut>[],
    };
    final ready = _destinationId != null && _boxes.isNotEmpty && !_sending;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.transferNewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            context.l10n.transferNewExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (centers.isEmpty)
            Text(context.l10n.transferNoDestinations)
          else
            DropdownButtonFormField<String>(
              initialValue: _destinationId,
              decoration: InputDecoration(
                labelText: context.l10n.transferDestinationLabel,
              ),
              items: [
                for (final center in centers)
                  DropdownMenuItem(value: center.id, child: Text(center.name)),
              ],
              onChanged: (value) => setState(() => _destinationId = value),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _scan,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(context.l10n.transferChooseBoxesTitle),
          ),
          const SizedBox(height: 12),
          if (_boxes.isEmpty)
            Text(
              context.l10n.transferNoBoxesYet,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            Text(
              context.l10n.boxCount(_boxes.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final box in _boxes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(box.code),
                subtitle: Text('${box.quantity} ${box.unit}'),
                trailing: IconButton(
                  tooltip: context.l10n.transferBoxRemove,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(
                    () => _boxes.removeWhere((chosen) => chosen.id == box.id),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.transferReasonLabel,
              helperText: context.l10n.transferReasonHelper,
            ),
          ),
          const SizedBox(height: 20),
          ConfirmButton(
            label: context.l10n.transferProposeAction,
            onPressed: ready ? _create : null,
          ),
        ],
      ),
    );
  }
}
