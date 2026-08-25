import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/api/generated/models/transfer_out.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../../centers/data/centers_providers.dart';
import '../data/transfers_providers.dart';
import '../domain/transfer_actions.dart';
import 'transfer_detail_view.dart';

/// Transferencias en las que participa este centro.
///
/// Lo primero que se lee de cada una es si sale o llega: para quien coordina,
/// «viene hacia mí» y «sale de aquí» son dos trabajos distintos, y el estado
/// solo importa después de saber cuál de los dos es. Por eso el filtro es la
/// dirección y no el estado, al revés que en cajas o envíos.
///
/// **El otro centro se nombra solo cuando la sesión puede resolverlo.** El
/// contrato manda identificadores y los dos endpoints de centros exigen
/// administración nacional, así que quien coordina —que es quien más usa esta
/// pantalla— sigue sin poder resolver el nombre, y la fila calla en vez de
/// enseñar un identificador. Para una administración nacional, que sí puede
/// listarlos, callar era perder algo a cambio de nada. La petición 3 de
/// `backend-requests.md` sigue siendo el arreglo de verdad: los nombres en el
/// contrato, para todo el mundo.
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
    final myCenterId = ref.watch(myCenterIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: _Header(
          transfers: transfers.valueOrNull ?? const [],
          myCenterId: myCenterId,
        ),
      ),
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
    // Lo que espera una decisión de este centro: solicitadas en las que somos
    // el origen, que es exactamente cuando el servidor deja aprobar o rechazar.
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
              ? 'Ninguna espera tu decisión'
              : waiting == 1
              ? '1 espera tu decisión'
              : '$waiting esperan tu decisión',
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
                      label: Text('${_directionLabel(value)} · $count'),
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
              // Una administración nacional no pertenece a ningún centro, así
              // que hablarle de «este centro» describe algo que no existe. Lo
              // encontró mirar la pantalla con esa sesión, no un test.
              myCenterId == null
                  ? 'No hay transferencias registradas.'
                  : 'Este centro no participa en ninguna transferencia.',
              textAlign: TextAlign.center,
            ),
          ),
        for (final transfer in shown)
          _TransferRow(transfer: transfer, direction: _directionOf(transfer)),
      ],
    );
  }
}

String _directionLabel(TransferDirection direction) => switch (direction) {
  TransferDirection.incoming => 'Entrantes',
  TransferDirection.outgoing => 'Salientes',
  TransferDirection.other => 'De otros centros',
};

class _TransferRow extends ConsumerWidget {
  const _TransferRow({required this.transfer, required this.direction});

  final TransferOut transfer;
  final TransferDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El otro centro se nombra **solo si esta sesión puede resolverlo**. Para
    // una coordinación el mapa viene vacío y la fila queda exactamente como
    // estaba: la dirección y la fecha, sin nombre y sin hueco. Enseñar un
    // identificador sería peor que no enseñar nada, y por eso la petición 3
    // —los nombres en el contrato de la transferencia— sigue siendo el arreglo
    // de verdad para quien no puede listarlos.
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
        TransferDirection.incoming => 'Entrante',
        TransferDirection.outgoing => 'Saliente',
        TransferDirection.other => 'Entre otros centros',
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
