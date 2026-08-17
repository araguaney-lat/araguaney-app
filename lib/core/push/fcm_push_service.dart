import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_destination.dart';
import 'push_service.dart';

/// **El único archivo del proyecto que importa Firebase.**
///
/// Esa concentración es deliberada y tiene un consumidor concreto: el sabor
/// `foss` se compila desde una rama que borra este archivo, quita las dos
/// dependencias del `pubspec.yaml` y devuelve [NoopPushService] en el provider.
/// Cuanto más pequeño sea ese parche, más fácil es mantenerlo al día. Ver
/// `docs/release/foss.md`.
class FcmPushService implements PushService {
  FcmPushService({FirebaseMessaging? messaging}) : _instance = messaging;

  FirebaseMessaging? _instance;
  bool _started = false;

  FirebaseMessaging get _fcm => _instance ??= FirebaseMessaging.instance;

  /// Arranca Firebase. Idempotente: dos aperturas de sesión seguidas no
  /// inicializan dos veces.
  ///
  /// **No pide el permiso de notificaciones.** En Android 13 y posteriores el
  /// token existe con permiso o sin él —lo que falta sin permiso es que el
  /// sistema muestre el aviso, no que haya dónde entregarlo—, así que registrar
  /// el destino no depende de una decisión que todavía no se le ha explicado a
  /// nadie. Pedirlo con su explicación en español es trabajo aparte.
  @override
  Future<void> start() async {
    if (_started) return;
    await Firebase.initializeApp();
    _started = true;
  }

  @override
  Future<String?> currentToken() => _fcm.getToken();

  @override
  Stream<String> get onTokenRotated => _fcm.onTokenRefresh;

  /// Avisos que alguien tocó.
  ///
  /// Son dos fuentes y las dos importan: la aplicación abierta en segundo plano
  /// recibe el toque por el flujo, y la aplicación cerrada del todo lo recibe
  /// como mensaje inicial. Escuchar solo la primera pierde exactamente el caso
  /// más común —el teléfono en el bolsillo— y es un error que no se nota hasta
  /// que alguien pregunta por qué la aplicación abrió en la pantalla de inicio.
  @override
  Stream<PushDestination> get onOpened {
    final tapped = FirebaseMessaging.onMessageOpenedApp.map(_destinationOf);

    return Stream.multi((controller) async {
      // Firebase antes que nada, y aquí y no en quien escucha.
      //
      // Quien se suscribe es la pantalla, que se monta en cuanto hay sesión; y
      // quien inicializaba Firebase era el atado de la sesión, por otro camino.
      // Cuando la pantalla ganaba esa carrera, `getInitialMessage()` lanzaba
      // `[core/no-app]`, la excepción mataba la suscripción, y tocar un aviso
      // dejaba de navegar durante toda la sesión — sin decir nada. Que la clase
      // garantice su propia inicialización quita la carrera de raíz; `start()`
      // es idempotente y no cuesta nada llamarlo de más.
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
  Future<PushPermission> permission() async =>
      _translate(await _fcm.getNotificationSettings());

  /// Pide el permiso del sistema.
  ///
  /// Quien llama ya explicó para qué sirve; aquí solo se pregunta. En Android
  /// esto abre el diálogo de notificaciones a partir de la versión 13, y en las
  /// anteriores devuelve concedido sin preguntar nada, que es como se
  /// comportaba el sistema entonces.
  @override
  Future<PushPermission> requestPermission() async =>
      _translate(await _fcm.requestPermission());

  static PushPermission _translate(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized => PushPermission.granted,
        // Provisional es el permiso silencioso de iOS: los avisos llegan, sin
        // sonido y sin pantalla de bloqueo. Llegan, que es lo que importa aquí.
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  static PushDestination _destinationOf(RemoteMessage message) =>
      parsePushDestination(
        message.data.map((key, value) => MapEntry(key, '$value')),
      );
}
