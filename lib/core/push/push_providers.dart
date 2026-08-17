import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'device_registrar.dart';
import 'fcm_push_service.dart';
import 'push_prompt_memory.dart';
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

final pushPromptMemoryProvider = Provider<PushPromptMemory>(
  (ref) => const PrefsPushPromptMemory(),
);

/// Si hay que ofrecer activar los avisos.
///
/// Se ofrece cuando todavía no llegan y **nunca se ofreció antes**. Lo segundo
/// es lo que hace falta en Android, donde el sistema no distingue a quien no ha
/// decidido de quien dijo que no: sin esa memoria, la invitación no aparecía
/// jamás, y nadie llegaba a ver el diálogo del sistema.
///
/// Un `foss` sin servicio de avisos responde `unavailable` y tampoco ofrece
/// nada, que es lo correcto: ahí no hay nada que activar.
final shouldOfferPushProvider = FutureProvider<bool>((ref) async {
  final permission = await ref.watch(pushPermissionProvider.future);
  if (permission != PushPermission.denied &&
      permission != PushPermission.notDetermined) {
    return false;
  }
  return !await ref.watch(pushPromptMemoryProvider).alreadyOffered();
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
