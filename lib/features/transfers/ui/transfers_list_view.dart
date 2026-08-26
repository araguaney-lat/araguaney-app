import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/transfer_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../centers/data/centers_providers.dart';
import '../data/transfers_providers.dart';
import '../domain/transfer_actions.dart';
import 'create_transfer_view.dart';
import 'transfer_detail_view.dart';

/// The transfers this centre takes part in.
///
/// The first thing read of each one is whether it leaves or arrives: for
/// whoever coordinates, «coming to me» and «leaving here» are two different
/// jobs, and the state only matters once you know which of the two it is. That
/// is why the filter is the direction and not the state, unlike boxes or
/// shipments.
///
/// **The other centre is named only when the session can resolve it.** The
/// contract sends identifiers and both centre endpoints require national
/// administration, so whoever coordinates — who uses this screen most — still
/// cannot resolve the name, and the row stays quiet instead of showing an
/// identifier. For a national administration, which can list them, staying
/// quiet was losing something in exchange for nothing. Request 3 of
/// `backend-requests.md` is still the real fix: the names in the contract, for
/// everybody.
class TransfersListView extends ConsumerStatefulWidget {
  const TransfersListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const TransfersListView());

  @override
  ConsumerState<TransfersListView> createState() => _TransfersListViewState();
}

class _TransfersListViewState extends ConsumerState<TransfersListView> {
  TransferDirection? _direction;

  @override
  Widget build(BuildContext context) {
    final transfers = ref.watch(transfersProvider);
    final myCenterId = ref.watch(actingCenterIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: _Header(
          transfers: transfers.valueOrNull ?? const [],
          myCenterId: myCenterId,
        ),
      ),
      // Proposing requires coordination — `require_coordinator` — and a centre
      // to leave from: whoever has neither does not see the button.
      floatingActionButton:
          ref.watch(isCenterCoordinatorProvider) && myCenterId != null
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).push(CreateTransferView.route()),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.transferNewTitle),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(transfersProvider),
        child: switch (transfers) {
          AsyncData(:final value) => _Loaded(
            transfers: value,
            myCenterId: myCenterId,
            direction: _direction,
            onDirection: (value) => setState(() => _direction = value),
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.transfers, required this.myCenterId});

  final List<TransferOut> transfers;
  final String? myCenterId;

  @override
  Widget build(BuildContext context) {
    // What is waiting for a decision from this centre: requested ones where we
    // are the origin, which is exactly when the server allows approving or
    // rejecting.
    final waiting = transfers.where((transfer) {
      final direction = transferDirection(
        fromCenterId: transfer.fromCenterId,
        toCenterId: transfer.toCenterId,
        myCenterId: myCenterId,
      );
      return direction == TransferDirection.outgoing &&
          transfer.status == 'REQUESTED';
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.navTransfers),
        Text(
          waiting == 0
              ? context.l10n.transfersNothingAwaits
              : context.l10n.transfersAwaitingDecision(waiting),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.transfers,
    required this.myCenterId,
    required this.direction,
    required this.onDirection,
  });

  final List<TransferOut> transfers;
  final String? myCenterId;
  final TransferDirection? direction;
  final ValueChanged<TransferDirection?> onDirection;

  TransferDirection _directionOf(TransferOut transfer) => transferDirection(
    fromCenterId: transfer.fromCenterId,
    toCenterId: transfer.toCenterId,
    myCenterId: myCenterId,
  );

  @override
  Widget build(BuildContext context) {
    final counts = <TransferDirection, int>{};
    for (final transfer in transfers) {
      counts.update(_directionOf(transfer), (n) => n + 1, ifAbsent: () => 1);
    }
    final shown = direction == null
        ? transfers
        : transfers.where((t) => _directionOf(t) == direction).toList();

    return ListView(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final value in TransferDirection.values)
                if (counts[value] case final count?)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${_directionLabel(context.l10n, value)} · $count',
                      ),
                      selected: direction == value,
                      onSelected: (chosen) =>
                          onDirection(chosen ? value : null),
                    ),
                  ),
            ],
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              // A national administration belongs to no centre, so talking to
              // them about «this centre» describes something that does not
              // exist. Looking at the screen with that session found it, not a
              // test.
              myCenterId == null
                  ? context.l10n.transfersEmpty
                  : context.l10n.transfersEmptyForCenter,
              textAlign: TextAlign.center,
            ),
          ),
        for (final transfer in shown)
          _TransferRow(transfer: transfer, direction: _directionOf(transfer)),
      ],
    );
  }
}

String _directionLabel(AppLocalizations l10n, TransferDirection direction) =>
    switch (direction) {
      TransferDirection.incoming => l10n.transferDirectionIncomingPlural,
      TransferDirection.outgoing => l10n.transferDirectionOutgoingPlural,
      TransferDirection.other => l10n.transferDirectionOtherPlural,
    };

class _TransferRow extends ConsumerWidget {
  const _TransferRow({required this.transfer, required this.direction});

  final TransferOut transfer;
  final TransferDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The other centre is named **only if this session can resolve it**. For a
    // coordination the map comes back empty and the row stays exactly as it
    // was: the direction and the date, with no name and no gap. Showing an
    // identifier would be worse than showing nothing, and that is why request 3
    // — the names in the transfer's contract — is still the real fix for
    // whoever cannot list them.
    final names = ref.watch(centerNamesProvider);
    final otherId = switch (direction) {
      TransferDirection.incoming => transfer.fromCenterId,
      TransferDirection.outgoing => transfer.toCenterId,
      TransferDirection.other => null,
    };
    final other = otherId == null ? null : names[otherId];
    final date = formatShortDate(transfer.createdAt);

    return ListTile(
      leading: Icon(switch (direction) {
        TransferDirection.incoming => Icons.call_received,
        TransferDirection.outgoing => Icons.call_made,
        TransferDirection.other => Icons.swap_horiz,
      }),
      title: Text(switch (direction) {
        TransferDirection.incoming => context.l10n.transferDirectionIncoming,
        TransferDirection.outgoing => context.l10n.transferDirectionOutgoing,
        TransferDirection.other => context.l10n.transferDirectionOther,
      }),
      subtitle: Text(other == null ? date : '$other · $date'),
      trailing: Chip(
        label: Text(transferStatusLabel(context.l10n, transfer.status)),
      ),
      onTap: () =>
          Navigator.of(context).push(TransferDetailView.route(transfer.id)),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
