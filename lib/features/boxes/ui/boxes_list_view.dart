import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/db/daos/boxes_dao.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/ui/stale_data_banner.dart';
import '../data/boxes_providers.dart';
import 'box_detail_view.dart';
import 'box_status_label.dart';

/// Cajas del centro. Se lee del cache, así que la pantalla se pinta igual con
/// señal y sin ella; el refresco ocurre detrás y el aviso de arriba dice de
/// cuándo son los datos.
class BoxesListView extends ConsumerStatefulWidget {
  const BoxesListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const BoxesListView());

  @override
  ConsumerState<BoxesListView> createState() => _BoxesListViewState();
}

class _BoxesListViewState extends ConsumerState<BoxesListView> {
  @override
  void initState() {
    super.initState();
    // Abrir la pantalla es la señal más clara de que alguien quiere datos
    // frescos. Va después del primer cuadro para no pedir red mientras se
    // construye el árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(syncCoordinatorProvider).refreshAll();
    });
  }

  Future<void> _refresh() => ref.read(syncCoordinatorProvider).refreshAll();

  @override
  Widget build(BuildContext context) {
    final boxes = ref.watch(boxesProvider);
    final marker = ref.watch(boxesSyncMarkerProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Cajas del centro')),
      body: Column(
        children: [
          StaleDataBanner(
            lastSyncedAt: marker?.lastSyncedAt,
            lastFailureCode: marker?.lastFailureCode,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: switch (boxes) {
                AsyncData(:final value) when value.isEmpty =>
                  const _EmptyView(),
                AsyncData(:final value) => _BoxList(boxes: value),
                AsyncError() => const _EmptyView(),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxList extends StatelessWidget {
  const _BoxList({required this.boxes});

  final List<BoxWithProduct> boxes;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: boxes.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final item = boxes[index];
      return ListTile(
        title: Text(item.box.code),
        subtitle: Text(
          '${item.productName ?? 'Producto no descargado'} · '
          '${item.box.quantity} ${item.box.unit}',
        ),
        trailing: Chip(label: Text(boxStatusLabel(item.box.status))),
        onTap: () => Navigator.of(
          context,
        ).push(BoxDetailView.route(boxId: item.box.id, code: item.box.code)),
      );
    },
  );
}

/// Sin cajas la explicación cambia con la conexión: no es lo mismo un centro
/// que todavía no registró nada que un dispositivo que nunca pudo descargar.
class _EmptyView extends ConsumerWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            children: [
              Icon(offline ? Icons.cloud_off : Icons.inbox_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                offline
                    ? 'Sin conexión y sin cajas descargadas. Conéctate una vez '
                          'para poder consultarlas después sin señal.'
                    : 'Este centro todavía no tiene cajas registradas.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
