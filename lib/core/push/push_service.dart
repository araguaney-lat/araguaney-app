import 'push_destination.dart';

/// Qué ha decidido quien usa el teléfono sobre recibir avisos.
enum PushPermission {
  /// Concedido: los avisos se muestran.
  granted,

  /// Denegado. No se vuelve a preguntar desde la aplicación; se cambia en los
  /// ajustes del sistema.
  denied,

  /// Todavía no se ha preguntado.
  notDetermined,

  /// No hay a quién preguntar: esta compilación no entrega avisos. Es el caso
  /// del sabor `foss`.
  unavailable,
}

/// El único punto por donde entra Firebase.
///
/// Todo lo que la aplicación necesita de los avisos cabe en estos cuatro
/// miembros, y ninguno menciona FCM. Esa es la razón de que exista: el sabor
/// `foss` compila con [NoopPushService] y sin una sola dependencia propietaria,
/// y el resto del código no distingue un sabor del otro.
abstract interface class PushService {
  /// Pone en marcha el servicio. Idempotente: llamarlo dos veces no duplica
  /// suscripciones.
  Future<void> start();

  /// La dirección de este dispositivo, o nulo si todavía no hay ninguna —sin
  /// permiso, sin servicios de Google, o en el sabor `foss`.
  Future<String?> currentToken();

  /// Direcciones nuevas. FCM rota el token por su cuenta, y cada rotación deja
  /// la anterior muerta: quien escuche esto tiene que registrar la nueva.
  Stream<String> get onTokenRotated;

  /// Avisos que alguien tocó, ya interpretados.
  Stream<PushDestination> get onOpened;

  /// Qué se decidió ya, sin preguntar nada.
  Future<PushPermission> permission();

  /// Pide el permiso al sistema. Devuelve lo que se decidió.
  Future<PushPermission> requestPermission();
}

/// Implementación que no hace nada.
///
/// Es la del sabor `foss` y también la de cualquier compilación sin Firebase
/// configurado. No es un placeholder: es el comportamiento correcto cuando no
/// hay a dónde entregar avisos, y el resto de la aplicación funciona igual.
class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<void> start() async {}

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get onTokenRotated => const Stream.empty();

  @override
  Stream<PushDestination> get onOpened => const Stream.empty();

  /// No hay permiso que pedir porque no hay avisos que entregar. Decir
  /// «denegado» sugeriría que alguien lo denegó.
  @override
  Future<PushPermission> permission() async => PushPermission.unavailable;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unavailable;
}
