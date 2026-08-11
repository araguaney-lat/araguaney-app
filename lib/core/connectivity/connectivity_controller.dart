import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_probe.dart';

/// Qué se sabe de la conexión con el servidor.
enum ConnectivityStatus {
  /// Una petición reciente llegó al servidor.
  online,

  /// No hay interfaz de red, o una petición reciente no llegó.
  offline,

  /// Hay interfaz levantada pero todavía nadie la ha probado.
  unknown,
}

/// Estado de conexión de la aplicación.
///
/// Combina dos hechos distintos a propósito. El sistema operativo dice si hay
/// una interfaz levantada; solo el tráfico real dice si hay servidor al otro
/// lado. Por eso una interfaz que aparece deja el estado en [
/// ConnectivityStatus.unknown] y no en `online`: el wifi de un centro de acopio
/// sin salida a internet es exactamente el caso que más importa no confundir.
class ConnectivityController extends Notifier<ConnectivityStatus> {
  StreamSubscription<bool>? _subscription;

  @override
  ConnectivityStatus build() {
    final probe = ref.watch(connectivityProbeProvider);

    _subscription = probe.onInterfaceChanged.listen(_onInterfaceChanged);
    ref.onDispose(() => _subscription?.cancel());

    // El primer sondeo no puede ir en `build`, que es síncrono. Solo se usa
    // para descubrir que no hay red: si la hay, el estado sigue sin probarse y
    // este resultado tardío no debe pisar una petición que ya haya llegado.
    unawaited(
      probe.hasInterface().then((hasInterface) {
        if (!hasInterface) state = ConnectivityStatus.offline;
      }),
    );

    return ConnectivityStatus.unknown;
  }

  /// Una petición llegó al servidor.
  void reportReachable() => state = ConnectivityStatus.online;

  /// Una petición no llegó: sin red, DNS o tiempo agotado.
  void reportUnreachable() => state = ConnectivityStatus.offline;

  void _onInterfaceChanged(bool hasInterface) {
    // Sin interfaz la respuesta es definitiva. Con interfaz solo se sabe que
    // vale la pena intentarlo.
    state = hasInterface
        ? ConnectivityStatus.unknown
        : ConnectivityStatus.offline;
  }
}

final connectivityProbeProvider = Provider<ConnectivityProbe>(
  (ref) => PluginConnectivityProbe(),
);

final connectivityControllerProvider =
    NotifierProvider<ConnectivityController, ConnectivityStatus>(
      ConnectivityController.new,
    );
