import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the refresh token between runs of the application.
///
/// **Only the refresh is persisted.** The access token lives in memory and dies
/// with the process: it is short-lived, it can be asked for again with the
/// refresh, and writing it to disk would only widen the surface of a shared or
/// lost device.
///
/// It also stores **which person** opened that session. The token does not say
/// — it carries centre and role, not identity — and without that a shared
/// device cannot tell whether whoever just signed in is the same person as the
/// previous shift or somebody who should not see their cache.
abstract interface class TokenStorage {
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);

  Future<String?> readUserId();

  /// Stores the identity. A null [userId] deletes it, which is the right thing
  /// when who they are could not be confirmed.
  Future<void> writeUserId(String? userId);

  Future<void> clear();
}

/// The implementation over the system's secure store: Keychain on iOS, and
/// EncryptedSharedPreferences (backed by the Keystore) on Android.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // In the package's Android 11, Keystore encryption (AES/GCM) is
            // already the default, and `resetOnError` leaves the store clean if
            // a credential turns out to be undecipherable: better to ask for a
            // session again than to start up against an unrecoverable error.
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              // The device is shared at a centre and the application syncs
              // when it opens rather than in the background: there is no need
              // to read while the phone is locked. `first_unlock` without
              // `this_device_only` would allow the credential to be restored
              // onto another device from a backup, and a session should not
              // travel like that.
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  @override
  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  @override
  Future<void> writeUserId(String? userId) => userId == null
      ? _storage.delete(key: _userIdKey)
      : _storage.write(key: _userIdKey, value: userId);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }
}
