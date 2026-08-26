import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/connectivity/connectivity_controller.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/daos/boxes_dao.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_outcome.dart';
import '../../../core/ui/event_timeline.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/status_labels.dart';
import '../data/boxes_providers.dart';
import 'box_label_view.dart';

/// A box's record, with the same content as its record on the web.
///
/// The box may not be in the cache: the synced window is bounded, and an old
/// label leads to a box that was never downloaded. In that case it is fetched,
/// and if there is no signal the screen says so instead of pretending it does
/// not exist.
class BoxDetailView extends ConsumerStatefulWidget {
  const BoxDetailView({super.key, required this.boxId, required this.code});

  final String boxId;
  final String code;

  static Route<void> route({required String boxId, required String code}) =>
      MaterialPageRoute<void>(
        builder: (_) => BoxDetailView(boxId: boxId, code: code),
      );

  @override
  ConsumerState<BoxDetailView> createState() => _BoxDetailViewState();
}

class _BoxDetailViewState extends ConsumerState<BoxDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  /// The result is handed to the coordinator so the connection state learns
  /// from this request too: if the record did not arrive for lack of network,
  /// the screen has to be able to say so instead of taking the box for
  /// non-existent.
  Future<void> _fetch() async {
    if (!mounted) return;
    final outcome = await ref
        .read(boxesRepositoryProvider)
        .refreshBox(widget.boxId);
    if (!mounted) return;
    ref.read(syncCoordinatorProvider).report([outcome]);
  }

  /// Sealing requires a connection: it decides about shared state that may be
  /// changing on another device. With no signal the screen explains that
  /// instead of queueing a blind decision.
  Future<void> _seal() async {
    setState(() => _sealing = true);
    final outcome = await ref.read(boxesRepositoryProvider).seal(widget.boxId);
    if (!mounted) return;

    ref.read(syncCoordinatorProvider).report([outcome]);
    setState(() => _sealing = false);

    if (outcome case SyncFailed(:final failure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.operatorMessage(context.l10n))),
      );
    }
  }

  bool _sealing = false;

  @override
  Widget build(BuildContext context) {
    final box = ref.watch(boxProvider(widget.boxId));
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.code),
        actions: [
          IconButton(
            tooltip: context.l10n.viewLabelAction,
            icon: const Icon(Icons.qr_code_2),
            onPressed: () =>
                Navigator.of(context).push(BoxLabelView.route(widget.code)),
          ),
        ],
      ),
      body: switch (box) {
        AsyncData(value: final item?) => _BoxFields(item: item),
        AsyncData() => const _NotCachedView(),
        AsyncError() => const _NotCachedView(),
        _ => const Center(child: CircularProgressIndicator()),
      },
      // Not sealed is not enough: a refused box is not sealed either and it is
      // not sealed but decided about. Offering it here sent the server a
      // request that could only come back denied, with the reason for the
      // refusal written right above it.
      bottomNavigationBar: switch (box) {
        AsyncData(value: final item?)
            when item.box.sealedAt == null && item.box.status == 'DRAFT' =>
          _SealBar(offline: offline, sealing: _sealing, onSeal: _seal),
        _ => null,
      },
    );
  }
}

class _SealBar extends StatelessWidget {
  const _SealBar({
    required this.offline,
    required this.sealing,
    required this.onSeal,
  });

  final bool offline;
  final bool sealing;
  final VoidCallback onSeal;

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
                context.l10n.sealNeedsConnection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          FilledButton.icon(
            onPressed: offline || sealing ? null : onSeal,
            icon: const Icon(Icons.lock_outline),
            label: Text(context.l10n.sealBoxTitle),
          ),
        ],
      ),
    ),
  );
}

class _BoxFields extends StatelessWidget {
  const _BoxFields({required this.item});

  final BoxWithProduct item;

  @override
  Widget build(BuildContext context) {
    final BoxRow(:status, :quantity, :unit, :batch, :expiryDate, :weightKg) =
        item.box;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        RecordField(
          label: context.l10n.statusLabel,
          value: boxStatusLabel(context.l10n, status),
        ),
        RecordField(
          label: context.l10n.productLabel,
          value: item.productName ?? context.l10n.productNotOnThisDevice,
        ),
        RecordField(
          label: context.l10n.quantityLabel,
          value: '$quantity $unit',
        ),
        if (batch case final batch?)
          RecordField(label: context.l10n.batchLabel, value: batch),
        if (expiryDate case final expiry?)
          RecordField(
            label: context.l10n.expiryLabel,
            value: formatShortDate(expiry),
          ),
        if (weightKg case final weight?)
          RecordField(label: context.l10n.weightLabel, value: '$weight kg'),
        if (item.box.rejectReason case final reason?)
          RecordField(label: context.l10n.rejectReasonLabel, value: reason),
        // The journey, at the end: it is consulted when something does not add
        // up, not every time the record is opened. And **only with a
        // connection** — the cache keeps a box's state, not its history.
        _Timeline(id: item.box.id),
      ],
    );
  }
}

/// The box's journey.
///
/// It answers «¿quién selló esto?» about the object somebody is holding, which
/// is the question asked in the bad moments. It goes at the end because it is
/// not consulted every time, and it stays quiet while it loads instead of
/// reserving room for something that may never arrive.
class _Timeline extends ConsumerWidget {
  const _Timeline({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(boxEventsProvider(id));

    return switch (events) {
      AsyncData(:final value) when value.isEmpty => const SizedBox.shrink(),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(context.l10n.timelineHeading),
          ),
          EventTimeline(
            events: value,
            statusLabel: (status) => boxStatusLabel(context.l10n, status),
          ),
        ],
      ),
      // A failure here does not break the record: what somebody came to see is
      // already above.
      _ => const SizedBox.shrink(),
    };
  }
}

class _NotCachedView extends ConsumerWidget {
  const _NotCachedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref.watch(connectivityControllerProvider) == ConnectivityStatus.offline;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(offline ? Icons.cloud_off : Icons.search_off, size: 48),
            const SizedBox(height: 16),
            Text(
              offline
                  ? context.l10n.boxNotCachedNeedsConnection
                  : context.l10n.boxNotFound,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
