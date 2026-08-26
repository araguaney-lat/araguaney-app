import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_probe.dart';

/// What is known about the connection to the server.
enum ConnectivityStatus {
  /// A recent request reached the server.
  online,

  /// There is no network interface, or a recent request did not arrive.
  offline,

  /// An interface is up but nobody has tried it yet.
  unknown,
}

/// The application's connection state.
///
/// It combines two different facts on purpose. The operating system says
/// whether an interface is up; only real traffic says whether there is a server
/// on the other side. That is why an interface appearing leaves the state at
/// [ConnectivityStatus.unknown] and not at `online`: a collection centre's wifi
/// with no way out to the internet is exactly the case it matters most not to
/// confuse.
class ConnectivityController extends Notifier<ConnectivityStatus> {
  StreamSubscription<bool>? _subscription;

  @override
  ConnectivityStatus build() {
    final probe = ref.watch(connectivityProbeProvider);

    _subscription = probe.onInterfaceChanged.listen(_onInterfaceChanged);
    ref.onDispose(() => _subscription?.cancel());

    // The first probe cannot go inside `build`, which is synchronous. It is
    // used only to find out there is no network: if there is, the state stays
    // untested, and this late result must not overwrite a request that already
    // got through.
    unawaited(
      probe.hasInterface().then((hasInterface) {
        if (!hasInterface) state = ConnectivityStatus.offline;
      }),
    );

    return ConnectivityStatus.unknown;
  }

  /// A request reached the server.
  void reportReachable() => state = ConnectivityStatus.online;

  /// A request did not arrive: no network, no DNS, or a timeout.
  void reportUnreachable() => state = ConnectivityStatus.offline;

  void _onInterfaceChanged(bool hasInterface) {
    // With no interface the answer is final. With one, all that is known is
    // that it is worth trying.
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
