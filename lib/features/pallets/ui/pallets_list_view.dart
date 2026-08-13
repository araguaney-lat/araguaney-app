import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/pallet_out.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/ui/record_field.dart';
import '../data/pallets_providers.dart';
import '../data/pallets_repository.dart';
import 'pallet_detail_view.dart';

/// Tarimas del centro.
///
/// Se consultan en línea y no se cachean, a diferencia de las cajas: una tarima
/// es estado compartido que otro dispositivo puede estar armando ahora mismo, y
/// una copia vieja invita a agregar una caja a algo que ya se cerró.
class PalletsListView extends ConsumerWidget {
  const PalletsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PalletsListView());

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final outcome = await ref.read(palletsRepositoryProvider).create();
    if (!context.mounted) return;

    switch (outcome) {
      case PalletChanged(:final value):
        ref.invalidate(palletsProvider);
        await Navigator.of(context).push(PalletDetailView.route(value.id));
      case PalletRejected(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.operatorMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallets = ref.watch(palletsProvider);
    final canOperate = ref.watch(canOperatePalletsProvider);
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarimas del centro')),
      floatingActionButton: canOperate && !offline
          ? FloatingActionButton.extended(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarima'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(palletsProvider),
        child: switch (pallets) {
          AsyncData(:final value) when value.isEmpty => const _Message(
            'Este centro no tiene tarimas abiertas.',
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _PalletTile(pallet: value[index]),
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

class _PalletTile extends StatelessWidget {
  const _PalletTile({required this.pallet});

  final PalletOut pallet;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(pallet.code),
    subtitle: Text(
      [
        pallet.status,
        if (pallet.closedAt case final closed?)
          'cerrada ${formatShortDate(closed)}',
      ].join(' · '),
    ),
    onTap: () => Navigator.of(context).push(PalletDetailView.route(pallet.id)),
  );
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
