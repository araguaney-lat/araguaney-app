import 'package:connectivity_plus/connectivity_plus.dart';

/// Lo que el sistema operativo sabe de la red: si hay alguna interfaz levantada.
///
/// Es una interfaz propia para que las pruebas no necesiten un canal de
/// plataforma, y para que el resto del código no dependa del paquete.
abstract interface class ConnectivityProbe {
  /// Cambios de interfaz. `true` cuando hay alguna levantada.
  Stream<bool> get onInterfaceChanged;

  Future<bool> hasInterface();
}

class PluginConnectivityProbe implements ConnectivityProbe {
  PluginConnectivityProbe({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onInterfaceChanged =>
      _connectivity.onConnectivityChanged.map(_isUp);

  @override
  Future<bool> hasInterface() async =>
      _isUp(await _connectivity.checkConnectivity());

  static bool _isUp(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
