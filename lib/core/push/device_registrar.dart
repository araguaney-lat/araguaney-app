import 'dart:io';

import '../api/generated/clients/devices_api.dart';
import '../api/generated/models/device_token_register.dart';
import '../api/generated/models/device_token_register_platform.dart';
import '../api/generated/models/device_token_unregister.dart';
import 'push_service.dart';

/// Le dice al servidor dónde entregar los avisos de quien tiene la sesión.
///
/// Las dos operaciones son idempotentes en el backend, así que aquí no se lleva
/// cuenta de si ya se registró: el caso normal es registrar un token que ya
/// existe, y el servidor lo reasigna a quien acaba de entrar. Eso es lo que
/// resuelve el teléfono compartido de un centro, y no hace falta nada especial
/// del lado de la aplicación.
///
/// **Ninguno de los dos métodos lanza.** Un registro fallido no puede impedir
/// entrar, y una baja fallida no puede dejar a alguien atrapado dentro de una
/// sesión que quiere cerrar.
class DeviceRegistrar {
  DeviceRegistrar({
    required DevicesApi api,
    required PushService push,
    required String appVersion,
    DeviceTokenRegisterPlatform? platform,
  }) : _devices = api,
       _pushService = push,
       _version = appVersion,
       _platform = platform ?? _currentPlatform();

  final DevicesApi _devices;
  final PushService _pushService;
  final String _version;
  final DeviceTokenRegisterPlatform _platform;

  /// Registra la dirección de este dispositivo. Devuelve si llegó a hacerlo.
  ///
  /// Sin token no hay nada que registrar y no es un error: es el sabor `foss`,
  /// o un permiso denegado, o un dispositivo sin servicios de Google.
  Future<bool> register([String? knownToken]) async {
    final token = knownToken ?? await _pushService.currentToken();
    if (token == null || token.isEmpty) return false;

    try {
      await _devices.registerDeviceV1DevicesPost(
        body: DeviceTokenRegister(
          token: token,
          platform: _platform,
          appVersion: _version,
        ),
      );
      return true;
    } on Object {
      // Sin señal en el arranque de un turno, esto falla y la persona entra
      // igual. La siguiente sesión —o la siguiente rotación— vuelve a
      // intentarlo, y el registro es idempotente.
      return false;
    }
  }

  /// Da de baja la dirección de este dispositivo.
  ///
  /// Se llama al cerrar sesión y **antes** de borrarla, porque el endpoint
  /// exige la sesión que se está entregando. No es limpieza opcional: en un
  /// teléfono que se comparte, saltárselo le entregaría a la siguiente persona
  /// los avisos de la anterior.
  ///
  /// Si falla —sin señal, típicamente— el cierre de sesión continúa. La ventana
  /// que eso abre se cierra sola: mientras no haya sesión nadie está mirando
  /// avisos, y en cuanto alguien entre, registrar reasigna el token a quien
  /// acaba de entrar.
  Future<bool> unregister([String? knownToken]) async {
    final token = knownToken ?? await _pushService.currentToken();
    if (token == null || token.isEmpty) return false;

    try {
      // Un token ajeno responde 200 y no hace nada, para no revelar si existe.
      // Aquí eso es un éxito, no un caso a distinguir.
      await _devices.unregisterDeviceV1DevicesUnregisterPost(
        body: DeviceTokenUnregister(token: token),
      );
      return true;
    } on Object {
      return false;
    }
  }

  static DeviceTokenRegisterPlatform _currentPlatform() {
    if (Platform.isAndroid) return DeviceTokenRegisterPlatform.android;
    if (Platform.isIOS) return DeviceTokenRegisterPlatform.ios;
    // El contrato solo reconoce esas dos. Cualquier otra cosa no es un destino
    // de avisos que el servidor sepa alcanzar.
    return DeviceTokenRegisterPlatform.$unknown;
  }
}
