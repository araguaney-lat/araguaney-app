import 'dart:io';

import '../api/generated/clients/devices_api.dart';
import '../api/generated/models/device_token_register.dart';
import '../api/generated/models/device_token_register_platform.dart';
import '../api/generated/models/device_token_unregister.dart';
import 'push_service.dart';

/// Tells the server where to deliver the notices of whoever has the session.
///
/// Both operations are idempotent on the backend, so nothing here keeps track
/// of whether it already registered: the normal case is registering a token
/// that already exists, and the server reassigns it to whoever just signed in.
/// That is what solves a centre's shared phone, and it needs nothing special on
/// the application's side.
///
/// **Neither method throws.** A failed registration cannot stop somebody
/// signing in, and a failed unregistration cannot trap somebody inside a
/// session they want to close.
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

  /// Registers this device's address. Returns whether it managed to.
  ///
  /// With no token there is nothing to register, and that is not an error: it
  /// is the `foss` flavour, or a denied permission, or a device without Google
  /// services.
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
      // With no signal at the start of a shift this fails and the person
      // signs in anyway. The next session — or the next rotation — tries
      // again, and registering is idempotent.
      return false;
    }
  }

  /// Unregisters this device's address.
  ///
  /// It is called on sign-out and **before** the session is cleared, because
  /// the endpoint requires the very session being handed back. It is not
  /// optional tidying: on a shared phone, skipping it would hand the previous
  /// person's notices to the next one.
  ///
  /// If it fails — typically with no signal — signing out carries on. The
  /// window that opens closes by itself: while there is no session nobody is
  /// looking at notices, and as soon as somebody signs in, registering
  /// reassigns the token to them.
  Future<bool> unregister([String? knownToken]) async {
    final token = knownToken ?? await _pushService.currentToken();
    if (token == null || token.isEmpty) return false;

    try {
      // Somebody else's token answers 200 and does nothing, so as not to
      // reveal whether it exists. Here that is a success, not a case to tell
      // apart.
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
    // The contract only recognises those two. Anything else is not a notice
    // destination the server knows how to reach.
    return DeviceTokenRegisterPlatform.$unknown;
  }
}
