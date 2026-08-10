import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el refresh token entre ejecuciones de la aplicación.
///
/// **Solo el refresh se persiste.** El access token vive en memoria y muere con
/// el proceso: dura poco, se puede volver a pedir con el refresh y escribirlo en
/// disco solo agrandaría la superficie de un dispositivo compartido o perdido.
/// También guarda **qué persona** abrió esa sesión. El token no lo dice —lleva
/// centro y rol, no identidad—, y sin ese dato un dispositivo compartido no
/// puede saber si quien acaba de entrar es la misma persona del turno anterior
/// o alguien que no debería ver su cache.
abstract interface class TokenStorage {
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);

  Future<String?> readUserId();

  /// Guarda la identidad. Un [userId] nulo la borra: es lo que corresponde
  /// cuando no se pudo confirmar quién es.
  Future<void> writeUserId(String? userId);

  Future<void> clear();
}

/// Implementación sobre el almacén seguro del sistema: Keychain en iOS y
/// EncryptedSharedPreferences (respaldado por el Keystore) en Android.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            // En Android 11 del paquete el cifrado con Keystore (AES/GCM) ya es
            // el comportamiento por defecto, y `resetOnError` deja el almacén
            // limpio si una credencial resulta indescifrable: mejor pedir
            // sesión otra vez que arrancar contra un error irrecuperable.
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              // El dispositivo se comparte en un centro y la aplicación
              // sincroniza al abrirse, no en segundo plano: no hace falta leer
              // con el teléfono bloqueado. `first_unlock` sin `this_device_only`
              // permitiría restaurar la credencial en otro equipo desde un
              // respaldo, y una sesión no debería viajar así.
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
