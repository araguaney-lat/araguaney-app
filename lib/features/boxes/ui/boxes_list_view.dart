import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/db/daos/boxes_dao.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_outcome.dart';
import '../../../core/ui/stale_data_banner.dart';
import '../../../core/ui/status_labels.dart';
import '../data/boxes_providers.dart';
import 'box_detail_view.dart';

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
  /// `null` es «todas». Se guarda el estado del backend y no una etiqueta: lo
  /// que se muestra se traduce al dibujar.
  String? _status;

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

  /// Cuántas hay de cada estado, para no ofrecer un filtro que deja la pantalla
  /// vacía sin avisar.
  Map<String, int> _countByStatus(List<BoxWithProduct> boxes) {
    final counts = <String, int>{};
    for (final item in boxes) {
      counts[item.box.status] = (counts[item.box.status] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final boxes = ref.watch(boxesProvider);
    final marker = ref.watch(boxesSyncMarkerProvider).valueOrNull;
    final all = boxes.valueOrNull ?? const <BoxWithProduct>[];
    final shown = _status == null
        ? all
        : all.where((item) => item.box.status == _status).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.boxesTitle),
        // El recuento va en el subtítulo y no en un chip: es contexto de la
        // pantalla, no un dato que se toque.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  context.l10n.boxesInCenter(all.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _StatusFilter(
                selected: _status,
                counts: _countByStatus(all),
                onSelected: (status) => setState(() => _status = status),
              ),
            ],
          ),
        ),
      ),
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
                AsyncData() when shown.isEmpty => _NoneInFilter(
                  status: _status!,
                ),
                AsyncData() => _BoxList(boxes: shown),
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

/// Los estados, en una fila que se desliza.
///
/// Son seis y no caben en el ancho de un teléfono. Se ordenan por el camino que
/// recorre una caja —abierta, sellada, en tarima, enviada— y no alfabéticamente,
/// porque quien busca «lo que falta por sellar» piensa en ese orden.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final String? selected;
  final Map<String, int> counts;
  final ValueChanged<String?> onSelected;

  /// El camino que recorre una caja, que es el orden en que se piensa: lo que
  /// falta por sellar, lo sellado, lo que ya salió, y aparte lo rechazado.
  static const _order = ['DRAFT', 'SEALED', 'SHIPPED', 'REJECTED'];

  @override
  Widget build(BuildContext context) {
    // Un estado que el backend agregue después aparece igual: se añade al final
    // en vez de desaparecer de la pantalla.
    final known = _order.where(counts.containsKey);
    final extra = counts.keys.where((s) => !_order.contains(s));

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Chip(
            label: context.l10n.allFilter,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in [...known, ...extra])
            _Chip(
              label:
                  '${boxStatusLabel(context.l10n, status)} · ${counts[status]}',
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

/// El filtro dejó la lista vacía. Se dice cuál, porque desde fuera parece que
/// el centro no tiene cajas.
class _NoneInFilter extends StatelessWidget {
  const _NoneInFilter({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Text(
          context.l10n.boxesEmptyForStatus(
            boxStatusLabel(context.l10n, status),
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}

class _BoxList extends StatelessWidget {
  const _BoxList({required this.boxes});

  final List<BoxWithProduct> boxes;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: boxes.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) => _BoxRow(item: boxes[index]),
  );
}

class _BoxRow extends ConsumerWidget {
  const _BoxRow({required this.item});

  final BoxWithProduct item;

  /// Sellar desde la lista, con lo que hay dentro delante.
  ///
  /// El diseño pone la acción aquí porque sellar es lo que más se repite en una
  /// jornada. Pero desde la lista no se ve el contenido, y sellar es la
  /// frontera entre «esto todavía se corrige» y «esto ya viaja»: la
  /// confirmación enseña producto y cantidad para que la decisión no sea a
  /// ciegas.
  Future<void> _seal(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.sealBoxConfirmTitle(item.box.code)),
        content: Text(
          context.l10n.sealBoxConfirmBody(
            item.productName ?? context.l10n.productNotCached,
            '${item.box.quantity}',
            item.box.unit,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.sealAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final outcome = await ref.read(boxesRepositoryProvider).seal(item.box.id);
    if (!context.mounted) return;

    ref.read(syncCoordinatorProvider).report([outcome]);
    if (outcome case SyncFailed(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.operatorMessage(context.l10n))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;
    // Por `sealedAt` y no por el texto del estado: es el dato que el backend
    // llena al sellar, y no depende de cómo se llame el estado esta semana. La
    // ficha de caja ya decidía así, y por eso fue la única pantalla a la que no
    // le afectó que la tabla de estados estuviera equivocada.
    final open = item.box.sealedAt == null && item.box.status == 'DRAFT';

    return ListTile(
      title: Text(item.box.code),
      subtitle: Text(
        '${item.productName ?? 'Producto no descargado'} · '
        '${item.box.quantity} ${item.box.unit}',
      ),
      // Sellar exige conexión: decide sobre estado compartido que puede estar
      // cambiando en otro dispositivo. Sin señal se muestra el estado y ya.
      trailing: open && !offline
          ? TextButton(
              onPressed: () => _seal(context, ref),
              child: Text(context.l10n.sealAction),
            )
          : Chip(label: Text(boxStatusLabel(context.l10n, item.box.status))),
      onTap: () => Navigator.of(
        context,
      ).push(BoxDetailView.route(boxId: item.box.id, code: item.box.code)),
    );
  }
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
                    ? context.l10n.boxesOfflineNoneCached
                    : context.l10n.boxesEmpty,
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
