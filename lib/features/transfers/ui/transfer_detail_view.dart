import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/transfer_detail_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../data/transfers_providers.dart';
import '../data/transfers_repository.dart';
import '../domain/transfer_actions.dart';

/// Una transferencia y lo que se puede hacer con ella ahora.
class TransferDetailView extends ConsumerWidget {
  const TransferDetailView({super.key, required this.transferId});

  final String transferId;

  static Route<void> route(String transferId) => MaterialPageRoute<void>(
    builder: (_) => TransferDetailView(transferId: transferId),
  );

  Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    TransferAction action,
  ) async {
    String? reason;
    if (action == TransferAction.reject) {
      reason = await _askReason(context);
      if (reason == null || !context.mounted) return;
    }

    final outcome = await ref
        .read(transfersRepositoryProvider)
        .perform(action: action, transferId: transferId, reason: reason);
    if (!context.mounted) return;

    ref
      ..invalidate(transferDetailProvider(transferId))
      ..invalidate(transfersProvider);

    if (outcome case TransferRefused(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.operatorMessage(context.l10n))),
      );
    }
  }

  /// Rechazar pide un motivo. Es lo único que el otro centro va a leer para
  /// entender por qué sus cajas no salieron.
  Future<String?> _askReason(BuildContext context) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.transferRejectReasonTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.l10n.reasonLabel,
            helperText: context.l10n.transferRejectReasonHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(context.l10n.actionReject),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfer = ref.watch(transferDetailProvider(transferId));
    final myCenterId = ref.watch(actingCenterIdProvider);
    final isNationalAdmin = ref.watch(isNationalAdminProvider);
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    final actions = switch (transfer) {
      AsyncData(:final value) => availableTransferActions(
        status: value.status,
        direction: transferDirection(
          fromCenterId: value.fromCenterId,
          toCenterId: value.toCenterId,
          myCenterId: myCenterId,
        ),
        isNationalAdmin: isNationalAdmin,
      ),
      _ => const <TransferAction>{},
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.transferRecordTitle)),
      body: switch (transfer) {
        AsyncData(:final value) => _Fields(
          transfer: value,
          myCenterId: myCenterId,
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
      bottomNavigationBar: actions.isEmpty
          ? null
          : _Actions(
              actions: actions,
              offline: offline,
              onAction: (action) => _perform(context, ref, action),
            ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.transfer, required this.myCenterId});

  final TransferDetailOut transfer;
  final String? myCenterId;

  @override
  Widget build(BuildContext context) {
    final direction = transferDirection(
      fromCenterId: transfer.fromCenterId,
      toCenterId: transfer.toCenterId,
      myCenterId: myCenterId,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        RecordField(
          label: context.l10n.statusLabel,
          value: transferStatusLabel(context.l10n, transfer.status),
        ),
        RecordField(
          label: context.l10n.addressLabel,
          value: switch (direction) {
            TransferDirection.incoming =>
              context.l10n.transferDirectionIncomingLong,
            TransferDirection.outgoing =>
              context.l10n.transferDirectionOutgoingLong,
            TransferDirection.other => context.l10n.transferDirectionOther,
          },
        ),
        RecordField(
          label: context.l10n.boxesTitle,
          value: '${transfer.boxes.length}',
        ),
        RecordField(
          label: context.l10n.transferStatusRequested,
          value: formatShortDate(transfer.createdAt),
        ),
        if (transfer.notes case final notes?)
          RecordField(label: context.l10n.notesLabel, value: notes),
        const Divider(),
        for (final box in transfer.boxes)
          ListTile(
            dense: true,
            title: Text(box.code),
            subtitle: Text(
              '${box.quantity} ${box.unit} · ${boxStatusLabel(context.l10n, box.status)}',
            ),
          ),
        if (transfer.events.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.l10n.transferHistoryHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final event in transfer.events)
            ListTile(
              dense: true,
              title: Text(
                '${transferStatusLabel(context.l10n, event.fromStatus ?? '—')} → '
                '${transferStatusLabel(context.l10n, event.toStatus)}',
              ),
              subtitle: Text(
                [formatShortDate(event.ts), ?event.note].join(' · '),
              ),
            ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.actions,
    required this.offline,
    required this.onAction,
  });

  final Set<TransferAction> actions;
  final bool offline;
  final void Function(TransferAction action) onAction;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (offline)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.l10n.transferNeedsConnection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Row(
            children: [
              for (final action in actions) ...[
                Expanded(
                  child: action == TransferAction.reject
                      ? OutlinedButton(
                          onPressed: offline ? null : () => onAction(action),
                          child: Text(
                            transferActionLabel(context.l10n, action),
                          ),
                        )
                      : FilledButton(
                          onPressed: offline ? null : () => onAction(action),
                          child: Text(
                            transferActionLabel(context.l10n, action),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
