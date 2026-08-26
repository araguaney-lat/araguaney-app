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

/// A pallet and the boxes it carries.
///
/// Building it is an online operation from beginning to end: another person may
/// be putting boxes on this very pallet from another phone, and deciding it
/// without signal would leave two versions of the same load.
class PalletDetailView extends ConsumerWidget {
  const PalletDetailView({super.key, required this.palletId});

  final String palletId;

  static Route<void> route(String palletId) => MaterialPageRoute<void>(
    builder: (_) => PalletDetailView(palletId: palletId),
  );

  /// Adds boxes by scanning them one after another.
  ///
  /// The camera does not close between one box and the next: whoever builds a
  /// pallet has their hands full and the stack in front of them. Each read
  /// leaves in the log what the server said, which is what decides whether a
  /// box can go in.
  Future<void> _scanBoxes(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(palletsRepositoryProvider);
    // Taken before navigating: inside the callback there is no guarantee this
    // context is still mounted.
    final l10n = context.l10n;

    await Navigator.of(context).push(
      ContinuousScanView.route(
        title: context.l10n.palletAddBoxes,
        hint: l10n.palletScanBoxesHint,
        onScanned: (payload) async {
          final scanned = parseScannedCode(payload);
          if (scanned is! BoxCode) {
            return ScanFeedback.rejected(l10n.scannedCodeIsNotABox);
          }

          final outcome = await repository.addBox(
            palletId: palletId,
            boxCode: scanned.code,
          );

          return switch (outcome) {
            PalletChanged(:final value) => ScanFeedback.accepted(
              l10n.palletBoxAdded(scanned.code, value.boxes.length),
            ),
            // The reason is the server's: that the box is not sealed, that it
            // is already on another pallet, that it belongs to another centre.
            // Translating it here would mean keeping two versions of the same
            // rule.
            PalletRejected(:final failure) => ScanFeedback.rejected(
              '${scanned.code} · ${failure.operatorMessage(l10n)}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.operatorMessage(context.l10n))),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.operatorMessage(context.l10n))),
      );
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
      appBar: AppBar(
        title: Text(pallet.valueOrNull?.code ?? context.l10n.palletTitle),
      ),
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
              ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
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
        label: context.l10n.statusLabel,
        value: palletStatusLabel(context.l10n, pallet.status),
      ),
      RecordField(
        label: context.l10n.boxesTitle,
        value: '${pallet.boxes.length}',
      ),
      if (pallet.tareWeightKg case final tare?)
        RecordField(label: context.l10n.tareLabel, value: '$tare kg'),
      if (pallet.boxesWeightKg case final boxes?)
        RecordField(label: context.l10n.boxesWeightLabel, value: '$boxes kg'),
      if (pallet.grossWeightKg case final gross?)
        RecordField(label: context.l10n.grossWeightLabel, value: '$gross kg'),
      // The difference is computed by the server. Here it is only shown, and
      // without adjectives: how much it matters is for whoever coordinates.
      if (pallet.weightDiscrepancyKg case final discrepancy?)
        RecordField(
          label: context.l10n.differenceLabel,
          value: '$discrepancy kg',
        ),
      if (pallet.heightCm case final height?)
        RecordField(label: context.l10n.heightLabel, value: '$height cm'),
      if (pallet.closedAt case final closed?)
        RecordField(
          label: context.l10n.palletStatusClosed,
          value: formatShortDate(closed),
        ),
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
                  tooltip: context.l10n.palletRemoveBoxTooltip,
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => onRemoveBox!(box.code),
                ),
        ),
      // The journey, at the end: it is consulted when something does not add
      // up.
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
      _ when closed => context.l10n.palletAlreadyClosed,
      _ when !canOperate => context.l10n.palletNeedsCoordinator,
      _ when offline => context.l10n.palletNeedsConnection,
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
                    label: Text(context.l10n.palletAddBoxes),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: actionable ? onClose : null,
                    icon: const Icon(Icons.lock_outline),
                    label: Text(context.l10n.actionClose),
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

/// The pallet's journey, for the same reason as a box's: it answers what
/// happened to what somebody has in front of them. A failure here does not
/// break the record.
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
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(context.l10n.timelineHeading),
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
