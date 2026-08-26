import 'dart:async';

import 'device_registrar.dart';
import 'push_service.dart';

/// Ties the notices' lifecycle to the session's.
///
/// A delivery address only makes sense while somebody is signed in: it is
/// registered when the session opens and unregistered when it closes. In
/// between, FCM can rotate the token on its own, and each rotation leaves the
/// previous address dead; that is why the subscription to the rotations lives
/// exactly as long as the session.
class PushSessionBinder {
  PushSessionBinder({
    required PushService push,
    required DeviceRegistrar registrar,
  }) : _pushService = push,
       _devices = registrar;

  final PushService _pushService;
  final DeviceRegistrar _devices;

  StreamSubscription<String>? _rotations;

  /// There is a session: this device becomes a valid destination and stays one
  /// even if the token changes.
  Future<void> onSessionStarted() async {
    await _pushService.start();
    await _devices.register();

    // `??=` and not a fresh subscription: two openings in a row — a password
    // change renews the session — must not leave two listeners registering the
    // same token twice.
    _rotations ??= _pushService.onTokenRotated.listen(
      (token) => unawaited(_devices.register(token)),
    );
  }

  /// The session is closing. Unregistering goes **before** it is cleared,
  /// because the endpoint requires the very session being handed back.
  Future<void> onSessionEnding() async {
    await _devices.unregister();
    await _rotations?.cancel();
    _rotations = null;
  }
}
