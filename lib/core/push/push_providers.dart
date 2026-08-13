import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'device_registrar.dart';
import 'push_service.dart';
import 'push_session_binder.dart';

/// El servicio de avisos activo.
///
/// Hoy siempre es el que no hace nada, y por dos razones distintas: el sabor
/// `foss` no lleva Firebase nunca, y el resto todavía no puede obtener un token
/// porque la aplicación no está registrada en el proyecto de Firebase. Cuando
/// exista ese registro, la implementación sobre FCM entra por aquí y no hay que
/// tocar nada más.
final pushServiceProvider = Provider<PushService>((ref) {
  if (!AppConfig.pushEnabled) return const NoopPushService();
  return const NoopPushService();
});

final deviceRegistrarProvider = Provider<DeviceRegistrar>(
  (ref) => DeviceRegistrar(
    api: ref.watch(restClientProvider).devices,
    push: ref.watch(pushServiceProvider),
    appVersion: ref.watch(appVersionProvider),
  ),
);

final pushSessionBinderProvider = Provider<PushSessionBinder>(
  (ref) => PushSessionBinder(
    push: ref.watch(pushServiceProvider),
    registrar: ref.watch(deviceRegistrarProvider),
  ),
);

/// Lo que la sesión llama al abrirse y al cerrarse.
///
/// Se exponen como funciones sueltas para que `core/auth` no tenga que conocer
/// nada de avisos: la sesión decide *cuándo*, y esta capa sabe *qué*. Es el
/// mismo arreglo que el borrado del modelo de lectura.
typedef SessionPushHook = Future<void> Function();

final onSessionStartedProvider = Provider<SessionPushHook>(
  (ref) => ref.watch(pushSessionBinderProvider).onSessionStarted,
);

final onSessionEndingProvider = Provider<SessionPushHook>(
  (ref) => ref.watch(pushSessionBinderProvider).onSessionEnding,
);
