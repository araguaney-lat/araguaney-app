import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity/connectivity_controller.dart';
import 'relative_time.dart';

/// Aviso de que lo que se ve puede no ser lo último.
///
/// Aparece cuando no hay conexión o cuando el último intento de refrescar
/// falló. Callarse en esos casos sería peor que mostrar datos viejos: quien
/// opera decide distinto si sabe que la caja que está mirando se sincronizó
/// ayer.
class StaleDataBanner extends ConsumerWidget {
  const StaleDataBanner({
    super.key,
    required this.lastSyncedAt,
    this.lastFailureCode,
    this.now,
  });

  final DateTime? lastSyncedAt;
  final String? lastFailureCode;

  /// Reloj inyectable para que las pruebas no dependan del momento en que se
  /// corren.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityControllerProvider);
    final offline = status == ConnectivityStatus.offline;
    if (!offline && lastFailureCode == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              offline ? Icons.cloud_off : Icons.sync_problem,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _message(offline),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _message(bool offline) {
    final headline = offline ? 'Sin conexión' : 'No se pudo actualizar';
    final moment = lastSyncedAt;

    if (moment == null) return '$headline · todavía no se descargó nada';
    return '$headline · datos de ${describeAge(moment, (now ?? DateTime.now)())}';
  }
}
