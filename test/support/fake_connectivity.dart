import 'dart:async';

import 'package:araguaney_app/core/connectivity/connectivity_probe.dart';

/// A connectivity probe driven by the test.
class FakeConnectivityProbe implements ConnectivityProbe {
  FakeConnectivityProbe({this.initialInterface = true});

  final _controller = StreamController<bool>.broadcast();

  /// What the first probe answers, the one that happens while the state is
  /// built.
  bool initialInterface;

  /// Simulates an interface change from the operating system.
  void emit({required bool hasInterface}) => _controller.add(hasInterface);

  @override
  Stream<bool> get onInterfaceChanged => _controller.stream;

  @override
  Future<bool> hasInterface() async => initialInterface;

  Future<void> dispose() => _controller.close();
}
