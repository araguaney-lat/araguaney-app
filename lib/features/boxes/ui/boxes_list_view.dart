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

/// The centre's boxes. It reads from the cache, so the screen paints the same
/// with signal and without it; the refresh happens behind, and the notice at
/// the top says how old the data is.
class BoxesListView extends ConsumerStatefulWidget {
  const BoxesListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const BoxesListView());

  @override
  ConsumerState<BoxesListView> createState() => _BoxesListViewState();
}

class _BoxesListViewState extends ConsumerState<BoxesListView> {
  /// `null` is «todas». The backend's state is stored and not a label: what is
  /// shown is translated when it is drawn.
  String? _status;

  @override
  void initState() {
    super.initState();
    // Opening the screen is the clearest sign that somebody wants fresh data.
    // It goes after the first frame so as not to ask for the network while the
    // tree is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(syncCoordinatorProvider).refreshAll();
    });
  }

  Future<void> _refresh() => ref.read(syncCoordinatorProvider).refreshAll();

  /// How many there are of each state, so as not to offer a filter that empties
  /// the screen without warning.
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
        // The count goes in the subtitle and not in a chip: it is context for
        // the screen, not a figure to be tapped.
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

/// The states, in a row that scrolls.
///
/// There are six and they do not fit across a phone. They are ordered by the
/// road a box travels — open, sealed, on a pallet, shipped — and not
/// alphabetically, because whoever is looking for «lo que falta por sellar»
/// thinks in that order.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final String? selected;
  final Map<String, int> counts;
  final ValueChanged<String?> onSelected;

  /// The road a box travels, which is the order it is thought about in: what is
  /// left to seal, what is sealed, what has left, and refused ones apart.
  static const _order = ['DRAFT', 'SEALED', 'SHIPPED', 'REJECTED'];

  @override
  Widget build(BuildContext context) {
    // A state the backend adds later still appears: it is added at the end
    // instead of disappearing from the screen.
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

/// The filter left the list empty. Which one is said, because from outside it
/// looks as though the centre has no boxes.
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

  /// Sealing from the list, with what is inside in front of you.
  ///
  /// The design puts the action here because sealing is what repeats most in a
  /// shift. But the contents are not visible from the list, and sealing is the
  /// boundary between «esto todavía se corrige» and «esto ya viaja»: the
  /// confirmation shows product and quantity so the decision is not made blind.
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
    // By `sealedAt` and not by the state's text: it is the field the backend
    // fills in when sealing, and it does not depend on what the state is called
    // this week. The box record already decided this way, and that is why it
    // was the only screen unaffected by the state table being wrong.
    final open = item.box.sealedAt == null && item.box.status == 'DRAFT';

    return ListTile(
      title: Text(item.box.code),
      subtitle: Text(
        '${item.productName ?? 'Producto no descargado'} · '
        '${item.box.quantity} ${item.box.unit}',
      ),
      // Sealing requires a connection: it decides about shared state that may
      // be changing on another device. With no signal the state is shown and
      // that is all.
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

/// With no boxes the explanation changes with the connection: a centre that has
/// not registered anything yet is not the same as a device that was never able
/// to download.
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
