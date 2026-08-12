import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables/queued_captures_table.dart';
import '../../../core/sync/sync_outcome.dart';
import '../../../core/ui/record_field.dart';
import '../data/capture_queue_sync.dart';
import '../data/intake_providers.dart';

/// Las capturas que esperan señal.
///
/// La pantalla existe para que la cola no sea invisible: una captura que nadie
/// puede ver es una captura que nadie sabe que se perdió. Nada se descarta solo
/// —una rechazada se queda aquí con el motivo del servidor— y el descarte lo
/// pide una persona.
class PendingCapturesView extends ConsumerStatefulWidget {
  const PendingCapturesView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const PendingCapturesView());

  @override
  ConsumerState<PendingCapturesView> createState() =>
      _PendingCapturesViewState();
}

class _PendingCapturesViewState extends ConsumerState<PendingCapturesView> {
  bool _flushing = false;

  Future<void> _flush() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _flushing = true);
    final report = await ref.read(captureQueueSyncProvider).flush(userId);
    if (!mounted) return;
    setState(() => _flushing = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_reportMessage(report))));
  }

  /// Qué se le dice a quien pulsó «intentar ahora». El motivo del servidor
  /// manda sobre el recuento: saber que no hay señal es más útil que saber que
  /// no se envió nada.
  static String _reportMessage(QueueFlushReport report) {
    if (report.stoppedBy case final failure?) return failure.operatorMessage;
    if (report.sent > 0 && report.remaining == 0) {
      return 'Se enviaron ${report.sent}. No queda nada pendiente.';
    }
    if (report.sent > 0) return 'Se enviaron ${report.sent}.';
    if (report.parked > 0) {
      return 'El servidor rechazó ${report.parked}. Revisa el motivo.';
    }
    return 'No había nada que enviar.';
  }

  Future<void> _discard(QueuedCaptureRow row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar esta captura?'),
        content: Text(
          'Se borra del dispositivo y no se envía. Lo que se registró en '
          'papel o en las cajas de ${row.summary} no se recupera desde aquí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(captureQueueRepositoryProvider).discard(row.captureId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final captures = ref.watch(queuedCapturesProvider);
    final codes = ref.watch(availableBoxCodesProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturas pendientes'),
        actions: [
          IconButton(
            tooltip: 'Intentar ahora',
            icon: const Icon(Icons.sync),
            onPressed: _flushing ? null : _flush,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_flushing) const LinearProgressIndicator(),
          _CodeBlockBanner(available: codes),
          Expanded(
            child: switch (captures) {
              AsyncData(:final value) when value.isEmpty => const _Empty(),
              AsyncData(:final value) => ListView.separated(
                itemCount: value.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _CaptureTile(
                  row: value[index],
                  onDiscard: () => _discard(value[index]),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Cuántos códigos quedan para capturar sin señal, y la forma de reponerlos.
///
/// Se repone **con** señal, que es el único momento en que se puede: quien baja
/// a un sótano con el bloque vacío se queda sin etiquetas hasta que vuelva a
/// subir.
class _CodeBlockBanner extends ConsumerStatefulWidget {
  const _CodeBlockBanner({required this.available});

  final int available;

  @override
  ConsumerState<_CodeBlockBanner> createState() => _CodeBlockBannerState();
}

class _CodeBlockBannerState extends ConsumerState<_CodeBlockBanner> {
  static const _blockSize = 50;
  bool _reserving = false;

  Future<void> _topUp() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _reserving = true);
    final outcome = await ref
        .read(boxCodeRepositoryProvider)
        .topUp(count: _blockSize, userId: userId);
    if (!mounted) return;
    setState(() => _reserving = false);

    final message = switch (outcome) {
      SyncSucceeded(:final itemCount) => 'Se reservaron $itemCount códigos.',
      SyncFailed(:final failure) => failure.operatorMessage,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text('Códigos disponibles: ${widget.available}'),
    subtitle: const Text('Se reservan con conexión y se gastan sin ella'),
    trailing: TextButton(
      onPressed: _reserving ? null : _topUp,
      child: const Text('Reservar'),
    ),
  );
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({required this.row, required this.onDiscard});

  final QueuedCaptureRow row;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final rejected = row.status == QueuedCaptureStatus.rejected;

    return ListTile(
      leading: Icon(
        rejected ? Icons.report_gmailerrorred_outlined : Icons.schedule,
      ),
      title: Text(row.summary),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rejected
                ? 'El servidor la rechazó'
                : 'Esperando conexión · ${row.attempts} '
                      '${row.attempts == 1 ? 'intento' : 'intentos'}',
          ),
          if (row.lastFailureMessage case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Text(
            'Capturada el ${formatShortDate(row.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: rejected
          ? IconButton(
              tooltip: 'Descartar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDiscard,
            )
          : null,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'No hay capturas esperando. Las que se hagan sin señal aparecerán '
        'aquí hasta que se envíen.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}
