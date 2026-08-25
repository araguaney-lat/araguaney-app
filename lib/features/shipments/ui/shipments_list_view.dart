import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/shipment_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../data/shipments_providers.dart';
import '../data/shipments_repository.dart';
import 'create_shipment_sheet.dart';
import 'shipment_record_view.dart';

/// Los envíos del centro.
///
/// Se consulta en línea siempre. Coordinar un envío exige señal de todos modos,
/// y un listado cacheado enseñaría como abierto uno que otra persona del centro
/// ya cerró desde el panel.
class ShipmentsListView extends ConsumerStatefulWidget {
  const ShipmentsListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ShipmentsListView());

  @override
  ConsumerState<ShipmentsListView> createState() => _ShipmentsListViewState();
}

class _ShipmentsListViewState extends ConsumerState<ShipmentsListView> {
  /// El camino que recorre un envío, que es el orden en que se piensa: se abre,
  /// se cierra, sale, llega y se cuadra.
  static const _order = [
    'OPEN',
    'CLOSED',
    'SHIPPED',
    'DELIVERED',
    'RECONCILED',
  ];

  String? _status;

  Future<void> _create() async {
    final draft = await CreateShipmentSheet.show(context);
    if (draft == null || !mounted) return;

    final outcome = await ref.read(shipmentsRepositoryProvider).create(draft);
    if (!mounted) return;

    switch (outcome) {
      case ShipmentDone(:final value):
        ref.invalidate(shipmentsProvider);
        await Navigator.of(context).push(ShipmentRecordView.route(value.id));
        if (mounted) ref.invalidate(shipmentsProvider);
      case ShipmentRefused(:final failure):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failure.operatorMessage(context.l10n))),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipments = ref.watch(shipmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Envíos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo envío'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(shipmentsProvider),
        child: switch (shipments) {
          AsyncData(:final value) => _Loaded(
            shipments: value,
            status: _status,
            onStatus: (status) => setState(() => _status = status),
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

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.shipments,
    required this.status,
    required this.onStatus,
  });

  final List<ShipmentOut> shipments;
  final String? status;
  final ValueChanged<String?> onStatus;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final shipment in shipments) {
      counts.update(shipment.status, (n) => n + 1, ifAbsent: () => 1);
    }
    final shown = status == null
        ? shipments
        : shipments.where((s) => s.status == status).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            shipments.length == 1
                ? '1 envío en el centro'
                : '${shipments.length} envíos en el centro',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        // Cada filtro lleva su conteo: ofrecer uno que vacía la pantalla sin
        // avisar es peor que no ofrecerlo.
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final value in _ShipmentsListViewState._order)
                if (counts[value] case final count?)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${shipmentStatusLabel(context.l10n, value)} · $count',
                      ),
                      selected: status == value,
                      onSelected: (chosen) => onStatus(chosen ? value : null),
                    ),
                  ),
            ],
          ),
        ),
        if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Todavía no hay envíos. Uno se abre cuando hay tarimas cerradas '
              'esperando salir.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final shipment in shown)
          ListTile(
            title: Text(shipment.destination),
            subtitle: Text(
              [
                formatShortDate(shipment.createdAt),
                ?shipment.carrier,
                ?shipment.reference,
              ].join(' · '),
            ),
            trailing: Chip(
              label: Text(shipmentStatusLabel(context.l10n, shipment.status)),
            ),
            onTap: () => Navigator.of(
              context,
            ).push(ShipmentRecordView.route(shipment.id)),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
