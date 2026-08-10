import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/boxes/data/boxes_providers.dart';
import '../../features/catalog/data/catalog_providers.dart';
import '../connectivity/connectivity_controller.dart';
import 'sync_outcome.dart';

/// Único sitio que decide cuándo se refresca el modelo de lectura.
///
/// Los repositorios no se suscriben a la conectividad por su cuenta: si cada
/// uno reaccionara, volver la señal dispararía tantas ráfagas como pantallas
/// abiertas hubiera, y entender por qué se hizo una petición exigiría revisar
/// todas. Aquí hay una respuesta a esa pregunta.
class SyncCoordinator {
  SyncCoordinator(this._ref) {
    _ref.onDispose(() => _disposed = true);
  }

  final Ref _ref;
  bool _running = false;

  /// Una sincronización sobrevive a la pantalla que la pidió: cerrar sesión
  /// desmonta los providers mientras las peticiones siguen en vuelo. Sin esta
  /// marca, la respuesta tardía intentaría escribir en un contenedor que ya no
  /// existe.
  bool _disposed = false;

  /// Refresca catálogo y cajas. Si ya hay un refresco en curso, no encola otro:
  /// al recuperar la señal es normal que lleguen varias señales seguidas.
  Future<void> refreshAll() async {
    if (_running || _disposed) return;
    _running = true;
    try {
      final outcomes = await Future.wait([
        _ref.read(catalogRepositoryProvider).refresh(),
        _ref.read(boxesRepositoryProvider).refresh(),
      ]);
      report(outcomes);
    } finally {
      _running = false;
    }
  }

  /// Traduce lo que pasó en las peticiones a estado de conexión.
  ///
  /// Un rechazo del servidor (un 403, un 422) **prueba que hay servidor**: se
  /// informa como en línea aunque la operación fallara. Solo un fallo de red
  /// marca sin señal.
  void report(List<SyncOutcome> outcomes) {
    if (outcomes.isEmpty || _disposed) return;

    final connectivity = _ref.read(connectivityControllerProvider.notifier);
    final reachable = outcomes.any(
      (outcome) => outcome is! SyncFailed || !outcome.isNetworkFailure,
    );

    reachable
        ? connectivity.reportReachable()
        : connectivity.reportUnreachable();
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);

  // Salir de «sin señal» es el momento en que vale la pena reintentar. No se
  // reacciona a cada cambio de interfaz: pasar de wifi a datos con el servidor
  // ya alcanzable no cambia nada de lo que hay en pantalla.
  ref.listen<ConnectivityStatus>(connectivityControllerProvider, (
    previous,
    next,
  ) {
    if (previous == ConnectivityStatus.offline &&
        next != ConnectivityStatus.offline) {
      coordinator.refreshAll();
    }
  });

  return coordinator;
});
