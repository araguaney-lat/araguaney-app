import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/pallet_out.dart';
import '../../../core/center/center_providers.dart';
import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../../core/ui/working_center_banner.dart';
import '../data/pallets_providers.dart';
import '../data/pallets_repository.dart';
import 'close_pallet_sheet.dart';
import 'pallet_detail_view.dart';

/// Tarimas del centro.
///
/// Se consultan en línea y no se cachean, a diferencia de las cajas: una tarima
/// es estado compartido que otro dispositivo puede estar armando ahora mismo, y
/// una copia vieja invita a agregar una caja a algo que ya se cerró.
class PalletsListView extends ConsumerStatefulWidget {
  const PalletsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PalletsListView());

  @override
  ConsumerState<PalletsListView> createState() => _PalletsListViewState();
}

class _PalletsListViewState extends ConsumerState<PalletsListView> {
  /// El camino que recorre una tarima, que es el orden en que se piensa.
  static const order = ['OPEN', 'CLOSED', 'SHIPPED'];

  String? _status;

  Future<void> _create() async {
    final outcome = await ref
        .read(palletsRepositoryProvider)
        .create(centerId: ref.read(writeCenterIdProvider));
    if (!mounted) return;

    switch (outcome) {
      case PalletChanged(:final value):
        ref.invalidate(palletsProvider);
        await Navigator.of(context).push(PalletDetailView.route(value.id));
        if (mounted) ref.invalidate(palletsProvider);
      case PalletRejected(:final failure):
        _say(failure.operatorMessage(context.l10n));
    }
  }

  /// Cerrar una tarima pide su peso, que es el dato que el envío necesita y que
  /// solo se puede tomar con la tarima delante. Por eso se cierra desde aquí y
  /// no hay que entrar a la ficha para hacerlo.
  Future<void> _close(PalletOut pallet) async {
    final weights = await ClosePalletSheet.show(context);
    if (weights == null || !mounted) return;

    final outcome = await ref
        .read(palletsRepositoryProvider)
        .close(
          palletId: pallet.id,
          grossWeightKg: weights.grossWeightKg,
          heightCm: weights.heightCm,
        );
    if (!mounted) return;

    switch (outcome) {
      case PalletChanged():
        ref.invalidate(palletsProvider);
      case PalletRejected(:final failure):
        _say(failure.operatorMessage(context.l10n));
    }
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final pallets = ref.watch(palletsProvider);
    final canOperate = ref.watch(canOperatePalletsProvider);
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(title: const _Header()),
      floatingActionButton: canOperate && !offline
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.palletNewAction),
            )
          : null,
      body: Column(
        children: [
          const WorkingCenterBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(palletsProvider),
              child: switch (pallets) {
                AsyncData(:final value) => _Loaded(
                  pallets: value,
                  status: _status,
                  onStatus: (status) => setState(() => _status = status),
                  // Cerrar decide sobre estado compartido: exige conexión, igual que
                  // sellar una caja.
                  onClose: canOperate && !offline ? _close : null,
                ),
                AsyncError(:final error) => _Message(
                  ApiErrorMapper.fromAny(error).operatorMessage(context.l10n),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pallets = ref.watch(palletsProvider).valueOrNull ?? const [];
    final open = pallets.where((p) => p.status == 'OPEN').length;
    final closed = pallets.where((p) => p.status == 'CLOSED').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.palletsTitle),
        // Abiertas y cerradas son las dos cifras que deciden qué hacer ahora:
        // una abierta admite cajas, una cerrada espera un envío.
        Text(
          context.l10n.palletOpenClosedCounts(open, closed),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.pallets,
    required this.status,
    required this.onStatus,
    required this.onClose,
  });

  final List<PalletOut> pallets;
  final String? status;
  final ValueChanged<String?> onStatus;
  final void Function(PalletOut pallet)? onClose;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final pallet in pallets) {
      counts.update(pallet.status, (n) => n + 1, ifAbsent: () => 1);
    }
    final shown = status == null
        ? pallets
        : pallets.where((p) => p.status == status).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final value in _PalletsListViewState.order)
                if (counts[value] case final count?)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${palletStatusLabel(context.l10n, value)} · $count',
                      ),
                      selected: status == value,
                      onSelected: (chosen) => onStatus(chosen ? value : null),
                    ),
                  ),
            ],
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: EdgeInsets.all(32),
            child: Text(context.l10n.palletsEmpty, textAlign: TextAlign.center),
          ),
        for (final pallet in shown)
          _PalletRow(
            pallet: pallet,
            onClose: pallet.status == 'OPEN' && onClose != null
                ? () => onClose!(pallet)
                : null,
          ),
      ],
    );
  }
}

class _PalletRow extends StatelessWidget {
  const _PalletRow({required this.pallet, required this.onClose});

  final PalletOut pallet;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    // El número de cajas no viaja en el listado; solo está en la ficha. Se dice
    // lo que sí se sabe en vez de contar algo que nadie mandó — y una tarima
    // recién abierta no sabe nada todavía, así que no lleva segunda línea: un
    // subtítulo vacío deja un hueco que se lee como algo roto.
    final details = [
      if (pallet.grossWeightKg case final weight?) '$weight kg',
      if (pallet.heightCm case final height?) '$height cm',
      if (pallet.closedAt case final closed?)
        context.l10n.palletClosedOn(formatShortDate(closed)),
      if (pallet.shipmentId != null) context.l10n.palletInShipment,
    ];

    return ListTile(
      title: Text(pallet.code),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: onClose != null
          ? TextButton(
              onPressed: onClose,
              child: Text(context.l10n.actionClose),
            )
          : Chip(label: Text(palletStatusLabel(context.l10n, pallet.status))),
      onTap: () =>
          Navigator.of(context).push(PalletDetailView.route(pallet.id)),
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
