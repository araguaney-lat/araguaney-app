import 'package:connectivity_plus/connectivity_plus.dart';

/// What the operating system knows about the network: whether any interface is
/// up.
///
/// It is an interface of our own so tests do not need a platform channel, and
/// so the rest of the code does not depend on the package.
abstract interface class ConnectivityProbe {
  /// Interface changes. `true` when one is up.
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
