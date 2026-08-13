import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'device_registrar.dart';
import 'fcm_push_service.dart';
import 'push_service.dart';
import 'push_session_binder.dart';

/// El servicio de avisos activo.
///
/// Esta línea y el archivo `fcm_push_service.dart` son todo lo que el sabor
/// `foss` tiene que quitar: su rama devuelve siempre [NoopPushService]. La
/// comprobación de [AppConfig.pushEnabled] se queda igualmente, porque un
/// binario compilado con `APP_FLAVOR=foss` desde esta rama tampoco debe
/// inicializar Firebase.
final pushServiceProvider = Provider<PushService>((ref) {
  if (!AppConfig.pushEnabled) return const NoopPushService();
  return FcmPushService();
});

/// Lo que ya se decidió sobre recibir avisos. Se invalida después de preguntar.
final pushPermissionProvider = FutureProvider<PushPermission>(
  (ref) => ref.watch(pushServiceProvider).permission(),
);

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
