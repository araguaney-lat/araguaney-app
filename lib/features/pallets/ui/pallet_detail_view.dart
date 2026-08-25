import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/pallet_detail_out.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/event_timeline.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../scanning/domain/scanned_code.dart';
import '../../scanning/ui/continuous_scan_view.dart';
import '../data/pallets_providers.dart';
import '../data/pallets_repository.dart';
import 'close_pallet_sheet.dart';

/// Una tarima y las cajas que lleva.
///
/// Armarla es una operación en línea de principio a fin: otra persona puede
/// estar poniendo cajas en esta misma tarima desde otro teléfono, y decidirlo
/// sin señal dejaría dos versiones del mismo bulto.
class PalletDetailView extends ConsumerWidget {
  const PalletDetailView({super.key, required this.palletId});

  final String palletId;

  static Route<void> route(String palletId) => MaterialPageRoute<void>(
    builder: (_) => PalletDetailView(palletId: palletId),
  );

  /// Agrega cajas escaneándolas una detrás de otra.
  ///
  /// La cámara no se cierra entre caja y caja: quien arma una tarima tiene las
  /// manos ocupadas y la pila enfrente. Cada lectura deja en el registro lo que
  /// dijo el servidor, que es quien decide si una caja puede entrar.
  Future<void> _scanBoxes(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(palletsRepositoryProvider);

    await Navigator.of(context).push(
      ContinuousScanView.route(
        title: 'Agregar cajas',
        hint: 'Apunta a la etiqueta de cada caja sellada.',
        onScanned: (payload) async {
          final scanned = parseScannedCode(payload);
          if (scanned is! BoxCode) {
            return const ScanFeedback.rejected('Ese código no es de una caja.');
          }

          final outcome = await repository.addBox(
            palletId: palletId,
            boxCode: scanned.code,
          );

          return switch (outcome) {
            PalletChanged(:final value) => ScanFeedback.accepted(
              '${scanned.code} · ${value.boxes.length} en la tarima',
            ),
            // El motivo es del servidor: que la caja no está sellada, que ya
            // está en otra tarima, que es de otro centro. Traducirlo aquí sería
            // mantener dos versiones de la misma regla.
            PalletRejected(:final failure) => ScanFeedback.rejected(
              '${scanned.code} · ${failure.operatorMessage}',
            ),
          };
        },
      ),
    );

    ref.invalidate(palletDetailProvider(palletId));
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final weights = await ClosePalletSheet.show(context);
    if (weights == null || !context.mounted) return;

    final outcome = await ref
        .read(palletsRepositoryProvider)
        .close(
          palletId: palletId,
          grossWeightKg: weights.grossWeightKg,
          heightCm: weights.heightCm,
        );
    if (!context.mounted) return;

    ref
      ..invalidate(palletDetailProvider(palletId))
      ..invalidate(palletsProvider);

    if (outcome case PalletRejected(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.operatorMessage)));
    }
  }

  Future<void> _removeBox(
    BuildContext context,
    WidgetRef ref,
    String boxCode,
  ) async {
    final outcome = await ref
        .read(palletsRepositoryProvider)
        .removeBox(palletId: palletId, boxCode: boxCode);
    if (!context.mounted) return;

    ref.invalidate(palletDetailProvider(palletId));
    if (outcome case PalletRejected(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.operatorMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallet = ref.watch(palletDetailProvider(palletId));
    final canOperate = ref.watch(canOperatePalletsProvider);
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    final open = pallet.valueOrNull?.closedAt == null;
    final actionable = canOperate && open && !offline;

    return Scaffold(
      appBar: AppBar(title: Text(pallet.valueOrNull?.code ?? 'Tarima')),
      body: switch (pallet) {
        AsyncData(:final value) => _Fields(
          pallet: value,
          onRemoveBox: actionable
              ? (code) => _removeBox(context, ref, code)
              : null,
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              ApiErrorMapper.fromAny(error).operatorMessage,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: pallet.hasValue
          ? _Actions(
              actionable: actionable,
              offline: offline,
              closed: !open,
              canOperate: canOperate,
              onScan: () => _scanBoxes(context, ref),
              onClose: () => _close(context, ref),
            )
          : null,
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.pallet, this.onRemoveBox});

  final PalletDetailOut pallet;
  final void Function(String boxCode)? onRemoveBox;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      RecordField(
        label: 'Estado',
        value: palletStatusLabel(context.l10n, pallet.status),
      ),
      RecordField(label: 'Cajas', value: '${pallet.boxes.length}'),
      if (pallet.tareWeightKg case final tare?)
        RecordField(label: 'Tara', value: '$tare kg'),
      if (pallet.boxesWeightKg case final boxes?)
        RecordField(label: 'Peso de las cajas', value: '$boxes kg'),
      if (pallet.grossWeightKg case final gross?)
        RecordField(label: 'Peso bruto', value: '$gross kg'),
      // La diferencia la calcula el servidor. Aquí solo se enseña, y sin
      // adjetivos: qué tanto importa lo decide quien coordina.
      if (pallet.weightDiscrepancyKg case final discrepancy?)
        RecordField(label: 'Diferencia', value: '$discrepancy kg'),
      if (pallet.heightCm case final height?)
        RecordField(label: 'Altura', value: '$height cm'),
      if (pallet.closedAt case final closed?)
        RecordField(label: 'Cerrada', value: formatShortDate(closed)),
      const Divider(),
      for (final box in pallet.boxes)
        ListTile(
          title: Text(box.code),
          subtitle: Text(
            '${box.quantity} ${box.unit} · ${boxStatusLabel(context.l10n, box.status)}',
          ),
          trailing: onRemoveBox == null
              ? null
              : IconButton(
                  tooltip: 'Quitar de la tarima',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onRemoveBox!(box.code),
                ),
        ),
      // El recorrido, al final: se consulta cuando algo no cuadra.
      _Timeline(id: pallet.id),
    ],
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.actionable,
    required this.offline,
    required this.closed,
    required this.canOperate,
    required this.onScan,
    required this.onClose,
  });

  final bool actionable;
  final bool offline;
  final bool closed;
  final bool canOperate;
  final VoidCallback onScan;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final reason = switch (true) {
      _ when closed => 'Esta tarima ya está cerrada.',
      _ when !canOperate =>
        'Armar tarimas es cosa de la coordinación del centro.',
      _ when offline =>
        'Armar una tarima necesita conexión: otra persona puede estar '
            'poniendo cajas en esta misma ahora mismo.',
      _ => null,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reason case final reason?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: actionable ? onScan : null,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Agregar cajas'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: actionable ? onClose : null,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// El recorrido de la tarima, por lo mismo que el de una caja: responde qué le
/// pasó a lo que alguien tiene delante. Un fallo aquí no rompe la ficha.
class _Timeline extends ConsumerWidget {
  const _Timeline({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(palletEventsProvider(id));

    return switch (events) {
      AsyncData(:final value) when value.isEmpty => const SizedBox.shrink(),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Recorrido'),
          ),
          EventTimeline(
            events: value,
            statusLabel: (status) => palletStatusLabel(context.l10n, status),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
