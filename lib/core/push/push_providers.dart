import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../auth/auth_providers.dart';
import '../config/app_config.dart';
import 'device_registrar.dart';
import 'fcm_push_service.dart';
import 'push_prompt_memory.dart';
import 'push_service.dart';
import 'push_session_binder.dart';

/// The active notice service.
///
/// This line and the file `fcm_push_service.dart` are everything the `foss`
/// flavour has to remove: its branch always returns [NoopPushService]. The
/// [AppConfig.pushEnabled] check stays anyway, because a binary built with
/// `APP_FLAVOR=foss` from this branch must not initialise Firebase either.
final pushServiceProvider = Provider<PushService>((ref) {
  if (!AppConfig.pushEnabled) return const NoopPushService();
  return FcmPushService();
});

/// What has already been decided about receiving notices. It is invalidated
/// after asking.
final pushPermissionProvider = FutureProvider<PushPermission>(
  (ref) => ref.watch(pushServiceProvider).permission(),
);

final pushPromptMemoryProvider = Provider<PushPromptMemory>(
  (ref) => const PrefsPushPromptMemory(),
);

/// Whether turning notices on should be offered.
///
/// It is offered when they do not arrive yet and **it was never offered
/// before**. The second half is what Android needs, where the system does not
/// tell somebody who has not decided from somebody who said no: without that
/// memory the invitation never appeared, and nobody ever got to see the
/// system's dialog.
///
/// A `foss` build with no notice service answers `unavailable` and offers
/// nothing either, which is right: there is nothing to turn on there.
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

/// What the session calls when it opens and when it closes.
///
/// They are exposed as loose functions so `core/auth` does not have to know
/// anything about notices: the session decides *when*, and this layer knows
/// *what*. It is the same arrangement as clearing the read model.
typedef SessionPushHook = Future<void> Function();

final onSessionStartedProvider = Provider<SessionPushHook>(
  (ref) => ref.watch(pushSessionBinderProvider).onSessionStarted,
);

final onSessionEndingProvider = Provider<SessionPushHook>(
  (ref) => ref.watch(pushSessionBinderProvider).onSessionEnding,
);
