import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_destination.dart';
import 'push_service.dart';

/// **The only file in the project that imports Firebase.**
///
/// That concentration is deliberate and has a concrete consumer: the `foss`
/// flavour builds from a branch that deletes this file, drops the two
/// dependencies from `pubspec.yaml` and returns [NoopPushService] from the
/// provider. The smaller that patch is, the easier it is to keep current. See
/// `docs/release/foss.md`.
class FcmPushService implements PushService {
  FcmPushService({FirebaseMessaging? messaging}) : _instance = messaging;

  FirebaseMessaging? _instance;
  bool _started = false;

  FirebaseMessaging get _fcm => _instance ??= FirebaseMessaging.instance;

  /// Starts Firebase. Idempotent: two sign-ins in a row do not initialise it
  /// twice.
  ///
  /// **Everything else in this class calls it first.** Callers cannot know what
  /// order the interface is built in, and the screen does sometimes arrive
  /// before the session's wiring: when that happened, `[core/no-app]` took out
  /// both the notice routing and the card that offers notices, silently.
  /// Having every method guarantee initialisation is cheaper than documenting
  /// an order nobody can check.
  ///
  /// **It does not ask for the notification permission.** On Android 13 and
  /// later the token exists with or without it — what is missing without
  /// permission is the system showing the notice, not somewhere to deliver it —
  /// so registering the destination does not depend on a decision nobody has
  /// had explained to them yet. Asking for it, with that explanation, is
  /// separate work.
  @override
  Future<void> start() async {
    if (_started) return;
    await Firebase.initializeApp();
    _started = true;
  }

  @override
  Future<String?> currentToken() async {
    await start();
    return _fcm.getToken();
  }

  @override
  Stream<String> get onTokenRotated => Stream.multi((controller) async {
    await start();
    final subscription = _fcm.onTokenRefresh.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  /// Notices somebody tapped.
  ///
  /// There are two sources and both matter: an application open in the
  /// background gets the tap through the stream, and one closed entirely gets
  /// it as the initial message. Listening only to the first misses exactly the
  /// most common case — the phone in a pocket — and it is a mistake nobody
  /// notices until somebody asks why the application opened on the home
  /// screen.
  @override
  Stream<PushDestination> get onOpened {
    final tapped = FirebaseMessaging.onMessageOpenedApp.map(_destinationOf);

    return Stream.multi((controller) async {
      // Firebase before anything else, and here rather than in the listener.
      //
      // What subscribes is the screen, which is built as soon as there is a
      // session; what initialised Firebase was the session's wiring, by another
      // path. When the screen won that race, `getInitialMessage()` threw
      // `[core/no-app]`, the exception killed the subscription, and tapping a
      // notice stopped navigating for the whole session — silently. Having the
      // class guarantee its own initialisation removes the race at the root;
      // `start()` is idempotent and calling it again costs nothing.
      await start();

      final initial = await _fcm.getInitialMessage();
      if (initial != null) controller.add(_destinationOf(initial));

      final subscription = tapped.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<PushPermission> permission() async {
    await start();
    return _translate(await _fcm.getNotificationSettings());
  }

  /// Asks the system for the permission.
  ///
  /// The caller has already explained what it is for; this only asks. On
  /// Android it opens the notifications dialog from version 13 on, and on
  /// earlier ones it returns granted without asking anything, which is how the
  /// system behaved then.
  @override
  Future<PushPermission> requestPermission() async {
    await start();
    return _translate(await _fcm.requestPermission());
  }

  static PushPermission _translate(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized => PushPermission.granted,
        // Provisional is iOS's quiet permission: notices arrive, with no
        // sound and no lock screen. They arrive, which is what matters here.
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  static PushDestination _destinationOf(RemoteMessage message) =>
      parsePushDestination(
        message.data.map((key, value) => MapEntry(key, '$value')),
      );
}
