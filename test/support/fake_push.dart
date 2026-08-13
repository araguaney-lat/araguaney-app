import 'dart:async';

import 'package:araguaney_app/core/push/push_destination.dart';
import 'package:araguaney_app/core/push/push_service.dart';

/// Servicio de avisos gobernado por la prueba.
class FakePushService implements PushService {
  FakePushService({this.token});

  /// La dirección que este dispositivo dice tener. Nula imita al sabor `foss`,
  /// a un permiso denegado o a un dispositivo sin servicios de Google.
  String? token;

  int startCount = 0;
  int permissionRequests = 0;

  /// Lo que responde el sistema. La prueba lo cambia para recorrer los caminos.
  PushPermission permissionStatus = PushPermission.notDetermined;

  /// Lo que la persona decide cuando se le pregunta.
  PushPermission answerWhenAsked = PushPermission.granted;

  final _rotations = StreamController<String>.broadcast();
  final _opened = StreamController<PushDestination>.broadcast();

  /// Simula que alguien tocó un aviso.
  void open(PushDestination destination) => _opened.add(destination);

  /// Simula que FCM rotó el token.
  void rotate(String newToken) {
    token = newToken;
    _rotations.add(newToken);
  }

  @override
  Future<void> start() async => startCount++;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get onTokenRotated => _rotations.stream;

  @override
  Stream<PushDestination> get onOpened => _opened.stream;

  @override
  Future<PushPermission> permission() async => permissionStatus;

  @override
  Future<PushPermission> requestPermission() async {
    permissionRequests++;
    return permissionStatus = answerWhenAsked;
  }

  Future<void> dispose() async {
    await _rotations.close();
    await _opened.close();
  }
}
