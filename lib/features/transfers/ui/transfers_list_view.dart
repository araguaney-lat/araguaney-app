import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/transfer_out.dart';
import '../../../core/ui/record_field.dart';
import '../data/transfers_providers.dart';
import '../domain/transfer_actions.dart';
import 'transfer_detail_view.dart';

/// Transferencias en las que participa este centro.
///
/// Lo primero que se lee de cada una es si sale o llega: para quien coordina,
/// «viene hacia mí» y «sale de aquí» son dos trabajos distintos, y el estado
/// solo importa después de saber cuál de los dos es.
class TransfersListView extends ConsumerWidget {
  const TransfersListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const TransfersListView());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(transfersProvider);
    final myCenterId = ref.watch(myCenterIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transferencias')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(transfersProvider),
        child: switch (transfers) {
          AsyncData(:final value) when value.isEmpty => const _Message(
            'Este centro no participa en ninguna transferencia.',
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _TransferTile(transfer: value[index], myCenterId: myCenterId),
          ),
          AsyncError(:final error) => _Message(
            ApiErrorMapper.fromAny(error).operatorMessage,
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({required this.transfer, required this.myCenterId});

  final TransferOut transfer;
  final String? myCenterId;

  @override
  Widget build(BuildContext context) {
    final direction = transferDirection(
      fromCenterId: transfer.fromCenterId,
      toCenterId: transfer.toCenterId,
      myCenterId: myCenterId,
    );

    return ListTile(
      leading: Icon(switch (direction) {
        TransferDirection.incoming => Icons.call_received,
        TransferDirection.outgoing => Icons.call_made,
        TransferDirection.other => Icons.swap_horiz,
      }),
      title: Text(switch (direction) {
        TransferDirection.incoming => 'Entrante',
        TransferDirection.outgoing => 'Saliente',
        TransferDirection.other => 'Entre otros centros',
      }),
      subtitle: Text(
        '${transferStatusLabel(transfer.status)} · '
        '${formatShortDate(transfer.createdAt)}',
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
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
