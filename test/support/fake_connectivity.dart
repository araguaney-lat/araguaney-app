import 'dart:async';

import 'package:araguaney_app/core/connectivity/connectivity_probe.dart';

/// Sonda de conectividad controlada por la prueba.
class FakeConnectivityProbe implements ConnectivityProbe {
  FakeConnectivityProbe({this.initialInterface = true});

  final _controller = StreamController<bool>.broadcast();

  /// Lo que responde el primer sondeo, el que ocurre al construir el estado.
  bool initialInterface;

  /// Simula un cambio de interfaz del sistema operativo.
  void emit({required bool hasInterface}) => _controller.add(hasInterface);

  @override
  Stream<bool> get onInterfaceChanged => _controller.stream;

  @override
  Future<bool> hasInterface() async => initialInterface;

  Future<void> dispose() => _controller.close();
}
