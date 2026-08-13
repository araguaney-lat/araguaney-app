import 'dart:async';

import 'device_registrar.dart';
import 'push_service.dart';

/// Ata el ciclo de vida de los avisos al de la sesión.
///
/// Una dirección de entrega solo tiene sentido mientras hay alguien dentro: se
/// registra al abrir la sesión y se da de baja al cerrarla. Entre medias, FCM
/// puede rotar el token por su cuenta, y cada rotación deja muerta la dirección
/// anterior; por eso la suscripción a las rotaciones vive exactamente el mismo
/// tiempo que la sesión.
class PushSessionBinder {
  PushSessionBinder({
    required PushService push,
    required DeviceRegistrar registrar,
  }) : _pushService = push,
       _devices = registrar;

  final PushService _pushService;
  final DeviceRegistrar _devices;

  StreamSubscription<String>? _rotations;

  /// Hay sesión: este dispositivo pasa a ser un destino válido y se mantiene
  /// así aunque el token cambie.
  Future<void> onSessionStarted() async {
    await _pushService.start();
    await _devices.register();

    // `??=` y no una suscripción nueva: dos aperturas seguidas —un cambio de
    // contraseña renueva la sesión— no pueden dejar dos escuchas registrando
    // el mismo token dos veces.
    _rotations ??= _pushService.onTokenRotated.listen(
      (token) => unawaited(_devices.register(token)),
    );
  }

  /// Se cierra la sesión. La baja va **antes** de borrarla, porque el endpoint
  /// exige justo la sesión que se entrega.
  Future<void> onSessionEnding() async {
    await _devices.unregister();
    await _rotations?.cancel();
    _rotations = null;
  }
}
