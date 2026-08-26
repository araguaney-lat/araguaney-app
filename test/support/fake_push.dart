import 'dart:async';

import 'package:araguaney_app/core/push/push_destination.dart';
import 'package:araguaney_app/core/push/push_service.dart';

/// A notice service governed by the test.
class FakePushService implements PushService {
  FakePushService({this.token});

  /// The address this device claims to have. Null imitates the `foss` flavour,
  /// a denied permission or a device without Google services.
  String? token;

  int startCount = 0;
  int permissionRequests = 0;

  /// What the system answers. The test changes it to walk the paths.
  PushPermission permissionStatus = PushPermission.notDetermined;

  /// What the person decides when they are asked.
  PushPermission answerWhenAsked = PushPermission.granted;

  final _rotations = StreamController<String>.broadcast();
  final _opened = StreamController<PushDestination>.broadcast();

  /// Simulates somebody having tapped a notice.
  void open(PushDestination destination) => _opened.add(destination);

  /// Simulates FCM having rotated the token.
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
