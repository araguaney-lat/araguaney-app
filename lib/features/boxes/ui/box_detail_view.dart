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

/// Ficha de una caja, con el mismo contenido que su registro en la web.
///
/// La caja puede no estar en el cache: la ventana sincronizada es acotada, y
/// una etiqueta vieja lleva a una caja que nunca se descargó. En ese caso se
/// intenta traerla, y si no hay señal la pantalla lo dice en vez de fingir que
/// no existe.
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

  /// El resultado se le pasa al coordinador para que el estado de conexión
  /// también aprenda de esta petición: si la ficha no llegó por falta de red,
  /// la pantalla tiene que poder decirlo en vez de dar la caja por inexistente.
  Future<void> _fetch() async {
    if (!mounted) return;
    final outcome = await ref
        .read(boxesRepositoryProvider)
        .refreshBox(widget.boxId);
    if (!mounted) return;
    ref.read(syncCoordinatorProvider).report([outcome]);
  }

  /// Sellar exige conexión: decide sobre estado compartido que puede estar
  /// cambiando en otro dispositivo. Sin señal la pantalla lo explica en vez de
  /// encolar una decisión a ciegas.
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
      // Sin sellar no basta: una caja rechazada tampoco lo está y no se sella,
      // se decide qué hacer con ella. Ofrecerlo aquí mandaba al servidor una
      // petición que solo podía volver negada, y con el motivo del rechazo
      // escrito justo encima.
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
          value: item.productName ?? 'No descargado en este dispositivo',
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
        // El recorrido, al final: se consulta cuando algo no cuadra, no cada
        // vez que se abre la ficha. Y **solo con conexión** — la caché guarda
        // el estado de una caja, no su historia.
        _Timeline(id: item.box.id),
      ],
    );
  }
}

/// El recorrido de la caja.
///
/// Responde «¿quién selló esto?» sobre el objeto que alguien tiene en la mano,
/// que es la pregunta que se hace en los malos momentos. Va al final porque no
/// se consulta cada vez, y calla mientras carga en vez de reservar sitio para
/// algo que quizá no llegue.
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
      // Un fallo aquí no rompe la ficha: lo que se vino a ver ya está arriba.
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
                  : 'No encontramos esta caja.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
