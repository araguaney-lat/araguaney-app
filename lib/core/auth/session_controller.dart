import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error_mapper.dart';
import '../api/api_failure.dart';
import '../api/generated/models/token.dart';
import '../db/db_providers.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';
import 'session.dart';
import 'token_storage.dart';

/// Dueño único del estado de sesión.
///
/// Es el único sitio que escribe el almacén seguro y el único que decide si hay
/// sesión. Cualquier otra capa lee.
class SessionController extends Notifier<SessionState> {
  late final AuthRepository _repository;
  late final TokenStorage _storage;
  late final Future<void> _restoration;

  /// La restauración inicial, para que quien pruebe pueda esperarla en vez de
  /// adivinar cuántos microtasks faltan.
  Future<void> get restoration => _restoration;

  @override
  SessionState build() {
    _repository = ref.read(authRepositoryProvider);
    _storage = ref.read(tokenStorageProvider);
    // El access token nunca se persiste, así que al arrancar no hay sesión
    // hasta que el refresh guardado la reconstruya. Va en un microtask porque
    // `build` no puede asignar `state` mientras se está construyendo.
    _restoration = Future<void>.microtask(restore);
    return const SessionRestoring();
  }

  /// Token vigente para el interceptor. Nulo si no hay sesión.
  String? get accessToken => switch (state) {
    SessionActive(:final session) => session.accessToken,
    _ => null,
  };

  /// Reconstruye la sesión desde el refresh guardado, al abrir la aplicación.
  Future<void> restore() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      state = const SessionAbsent();
      return;
    }

    try {
      final token = await _repository.refresh(refreshToken);
      await _adopt(token);
    } on Object catch (error) {
      final failure = _failureFor(error);
      if (failure.isRetryable) {
        // No se pudo verificar la sesión, pero el servidor tampoco dijo que
        // fuera inválida. **La credencial se conserva**: sin señal no se puede
        // volver a iniciar sesión, así que borrarla dejaría el dispositivo
        // inservible justo en el sótano donde más falta hace. Al volver la
        // conexión, restaurar vuelve a intentarlo.
        state = SessionAbsent(failureMessage: failure.operatorMessage);
        return;
      }
      // El servidor sí dijo que no sirve: vencido, revocado o reutilizado.
      await _clear(message: failure.operatorMessage);
    }
  }

  Future<void> logIn({
    required String username,
    required String password,
  }) async {
    try {
      final result = await _repository.login(
        username: username,
        password: password,
      );
      switch (result) {
        case LoginSucceeded(:final token):
          await _adopt(token, identifyUser: true);
        case LoginNeedsTotp(:final partialToken):
          state = SessionAwaitingTotp(partialToken: partialToken);
      }
    } on Object catch (error) {
      state = SessionAbsent(failureMessage: _messageFor(error));
    }
  }

  Future<void> submitTotpCode(String code) async {
    final current = state;
    if (current is! SessionAwaitingTotp) return;

    try {
      final token = await _repository.totpChallenge(
        partialToken: current.partialToken,
        code: code,
      );
      await _adopt(token, identifyUser: true);
    } on Object catch (error) {
      final failure = _failureFor(error);
      // Un token parcial caduca en minutos. Si venció, se vuelve al inicio de
      // sesión en vez de dejar a alguien tecleando códigos contra una puerta
      // que ya se cerró.
      if (failure is UnauthorizedFailure) {
        state = SessionAbsent(failureMessage: failure.operatorMessage);
      } else {
        state = SessionAwaitingTotp(
          partialToken: current.partialToken,
          failureMessage: failure.operatorMessage,
        );
      }
    }
  }

  /// Cancela el segundo factor y vuelve al inicio de sesión.
  void cancelTotp() => state = const SessionAbsent();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // El backend devuelve una sesión nueva, así que el cambio de contraseña
    // también renueva las credenciales del dispositivo.
    final token = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _adopt(token);
  }

  /// Renueva la sesión. La usa el interceptor ante un 401.
  Future<String> renew() async {
    final refreshToken =
        switch (state) {
          SessionActive(:final session) => session.refreshToken,
          _ => null,
        } ??
        await _storage.readRefreshToken();

    if (refreshToken == null) {
      throw const UnauthorizedFailure(
        code: 'NO_REFRESH_TOKEN',
        message: 'No hay credencial para renovar la sesión',
      );
    }

    final token = await _repository.refresh(refreshToken);
    await _adopt(token);
    return token.accessToken;
  }

  Future<void> logOut() async {
    final refreshToken = switch (state) {
      SessionActive(:final session) => session.refreshToken,
      _ => null,
    };
    await _repository.logout(refreshToken);
    await _clear();
  }

  /// Deja el dispositivo sin sesión. La llama el interceptor cuando la
  /// renovación fracasa.
  Future<void> expire() =>
      _clear(message: 'Tu sesión expiró. Inicia sesión de nuevo.');

  /// Adopta el token como sesión activa.
  ///
  /// [identifyUser] solo es cierto donde la persona puede haber cambiado: al
  /// iniciar sesión y al superar el segundo factor. Restaurar y renovar parten
  /// de un refresh guardado, y un refresh no se convierte en otra persona.
  Future<void> _adopt(Token token, {bool identifyUser = false}) async {
    // El backend rota el refresh en cada uso: se guarda el nuevo o el anterior
    // queda inservible en el dispositivo.
    if (token.refreshToken case final refresh?) {
      await _storage.writeRefreshToken(refresh);
    }

    final userId = identifyUser
        ? await _adoptIdentity(token.accessToken)
        : await _storage.readUserId();

    state = SessionActive(Session.fromToken(token, userId: userId));
  }

  /// Resuelve quién inició sesión y decide si el cache del turno anterior
  /// sobrevive.
  ///
  /// Se borra salvo que la identidad coincida con la guardada. Los dos casos
  /// que parecen excesivos son los que importan: una instalación nueva no tiene
  /// identidad guardada y borra una base vacía, que no cuesta nada; y si el
  /// servidor no contesta quién es, se borra igual. Fallar hacia el borrado es
  /// la única dirección segura, porque la alternativa es enseñarle los datos de
  /// una persona a la siguiente que agarre el teléfono del centro.
  Future<String?> _adoptIdentity(String accessToken) async {
    final previous = await _storage.readUserId();

    String? current;
    try {
      current = (await _repository.me(accessToken)).id;
    } on Object {
      current = null;
    }

    if (current == null || current != previous) {
      await ref.read(readModelResetProvider)();
    }
    await _storage.writeUserId(current);

    return current;
  }

  Future<void> _clear({String? message}) async {
    await _storage.clear();
    state = SessionAbsent(failureMessage: message);
  }

  ApiFailure _failureFor(Object error) => ApiErrorMapper.fromAny(error);

  String _messageFor(Object error) => _failureFor(error).operatorMessage;
}
