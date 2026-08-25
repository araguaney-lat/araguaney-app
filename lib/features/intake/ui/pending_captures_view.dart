import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/refusal_copy.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/tables/queued_captures_table.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/sync/sync_outcome.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/theme/app_theme.dart';
import '../../catalog/data/catalog_providers.dart';
import '../data/capture_queue_sync.dart';
import '../data/intake_providers.dart';
import '../domain/queued_capture_lines.dart';

/// Las capturas que esperan señal.
///
/// La pantalla existe para que la cola no sea invisible: una captura que nadie
/// puede ver es una captura que nadie sabe que se perdió. Nada se descarta solo
/// —una rechazada se queda aquí con el motivo del servidor— y tanto descartar
/// como reintentar los pide una persona.
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

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(_reportMessage(context.l10n, report))),
    );
  }

  /// Qué se le dice a quien pulsó «sincronizar». El motivo del servidor manda
  /// sobre el recuento: saber que no hay señal es más útil que saber que no se
  /// envió nada.
  static String _reportMessage(AppLocalizations l10n, QueueFlushReport report) {
    if (report.stoppedBy case final failure?) {
      return failure.operatorMessage(l10n);
    }
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
        title: Text(context.l10n.intakeDescartarEstaCaptura),
        content: Text(
          'Se borra del dispositivo y no se envía. Lo que se registró en '
          'papel o en las cajas de ${row.summary} no se recupera desde aquí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.accountConservar),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.intakeDescartar),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(captureQueueRepositoryProvider).discard(row.captureId);
    }
  }

  /// Devolver a la cola una captura aparcada. No se pregunta antes porque no
  /// destruye nada: vuelve a intentarlo con la misma llave de captura, y si el
  /// motivo sigue en pie el servidor la aparcará otra vez con el mismo texto.
  Future<void> _retry(QueuedCaptureRow row) async {
    await ref.read(captureQueueRepositoryProvider).retry(row.captureId);
    if (!mounted) return;
    await _flush();
  }

  @override
  Widget build(BuildContext context) {
    final captures = ref.watch(queuedCapturesProvider);
    final products = ref.watch(productTypesProvider(null)).valueOrNull ?? [];
    final codes = ref.watch(availableBoxCodesProvider).valueOrNull ?? 0;
    final queued = captures.valueOrNull?.length ?? 0;

    final names = {
      for (final product in products) product.id: product.displayName,
    };

    return Scaffold(
      appBar: AppBar(
        title: const _Header(),
        bottom: _flushing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: switch (captures) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReadinessStrip(
              products: products.length,
              codes: codes,
              queued: queued,
            ),
            const SizedBox(height: 12),
            _Actions(onSync: _flushing ? null : _flush),
            const SizedBox(height: 16),
            if (value.isEmpty)
              const _Empty()
            else
              for (final row in value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QueuedCard(
                    row: row,
                    lines: queuedCaptureLines(row.payload, names),
                    onRetry: () => _retry(row),
                    onDiscard: () => _discard(row),
                  ),
                ),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.l10n.intakePendientesDeEnvio),
      Text(
        context.l10n.intakeNadaSePierdeTodoEspera,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// Con qué se cuenta para trabajar sin señal, en tres números.
///
/// Están juntos porque se leen juntos: bajar a un sótano con catálogo pero sin
/// códigos, o con códigos pero con la cola llena, son situaciones distintas y
/// ninguna se ve mirando un solo número.
class _ReadinessStrip extends StatelessWidget {
  const _ReadinessStrip({
    required this.products,
    required this.codes,
    required this.queued,
  });

  final int products;
  final int codes;
  final int queued;

  // `IntrinsicHeight` para que las tres celdas midan lo mismo: sus rótulos
  // parten en distinto número de líneas y tres cajas de alturas distintas se
  // leen como tres cosas distintas, que es justo lo contrario de lo que son.
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _Cell(
            label: context.l10n.intakeProductosDescargados,
            value: products,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Cell(
            label: context.l10n.intakeCodigosApartados,
            value: codes,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _Cell(label: context.l10n.intakeCapturasEnCola, value: queued),
        ),
      ],
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: palette.noticeFill,
        border: Border.all(color: palette.noticeBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.noticeInk,
            ),
          ),
          // Al fondo de la celda, no debajo del rótulo: «Capturas en cola»
          // cabe en una línea y los otros dos rótulos parten en dos, así que
          // apoyados arriba los tres números quedaban a distinta altura y la
          // fila dejaba de leerse como una fila.
          const Spacer(),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: palette.noticeInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.onSync});

  final VoidCallback? onSync;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  static const _blockSize = 50;
  bool _reserving = false;

  /// Se reponen **con** señal, que es el único momento en que se puede: quien
  /// baja a un sótano con el bloque vacío se queda sin etiquetas hasta subir.
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
      SyncFailed(:final failure) => failure.operatorMessage(context.l10n),
    };
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: ConfirmButton(
          label: context.l10n.intakeSincronizar,
          onPressed: widget.onSync,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: OutlinedButton(
          onPressed: _reserving ? null : _topUp,
          child: Text(context.l10n.intakeReservarCodigos),
        ),
      ),
    ],
  );
}

class _QueuedCard extends StatelessWidget {
  const _QueuedCard({
    required this.row,
    required this.lines,
    required this.onRetry,
    required this.onDiscard,
  });

  final QueuedCaptureRow row;
  final List<String> lines;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rejected = row.status == QueuedCaptureStatus.rejected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.summary, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(_when(row), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(rejected: rejected),
              ],
            ),
            if (lines.isNotEmpty) const SizedBox(height: 10),
            for (final line in lines)
              Text('· $line', style: theme.textTheme.bodySmall),
            // La copia propia si conocemos el código, y si no las palabras
            // que mandó el servidor. Lo guardado es lo segundo siempre: ver
            // `capture_queue_sync`.
            if (refusalCopyFor(context.l10n, row.lastFailureCode ?? '') ??
                    row.lastFailureMessage
                case final message?) ...[
              const SizedBox(height: 10),
              Text(message, style: theme.textTheme.bodyMedium),
            ],
            // Reintentar y descartar solo aparecen en una captura aparcada.
            // Una que sigue esperando señal no necesita que nadie decida nada:
            // se reintenta sola en cuanto haya red.
            if (rejected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRetry,
                      child: Text(context.l10n.actionRetry),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: TextButton(
                      onPressed: onDiscard,
                      child: Text(context.l10n.intakeDescartar),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Cuándo se capturó y cuántas veces se ha intentado.
  ///
  /// Sin denominador: la cola reintenta mientras haya motivo para hacerlo y no
  /// tiene un máximo. Escribir «intento 1 de 5» pondría en pantalla un límite
  /// que este sistema no tiene.
  static String _when(QueuedCaptureRow row) => [
    formatShortDateTime(row.createdAt),
    if (row.attempts > 0) 'intento ${row.attempts}' else 'sin intentos todavía',
  ].join(' · ');
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.rejected});

  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: rejected ? palette.alertFill : palette.noticeFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rejected ? 'Rechazada' : 'Pendiente',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: rejected ? palette.alertInk : palette.noticeInk,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Text(
      context.l10n.intakeNoHayCapturasEsperandoLas,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}
