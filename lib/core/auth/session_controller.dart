import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_error_mapper.dart';
import '../api/api_failure.dart';
import '../api/generated/models/token.dart';
import '../api/generated/models/user_out.dart';
import '../db/db_providers.dart';
import '../push/push_providers.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';
import 'session.dart';
import 'token_storage.dart';

/// The single owner of the session state.
///
/// It is the only place that writes the secure store and the only one that
/// decides whether there is a session. Every other layer reads.
class SessionController extends Notifier<SessionState> {
  late final AuthRepository _repository;
  late final TokenStorage _storage;
  late final Future<void> _restoration;

  /// The initial restoration, so a test can await it instead of guessing how
  /// many microtasks are left.
  Future<void> get restoration => _restoration;

  @override
  SessionState build() {
    _repository = ref.read(authRepositoryProvider);
    _storage = ref.read(tokenStorageProvider);
    // The access token is never persisted, so at start-up there is no session
    // until the stored refresh rebuilds it. It goes in a microtask because
    // `build` cannot assign `state` while it is still building.
    _restoration = Future<void>.microtask(restore);
    return const SessionRestoring();
  }

  /// The current token, for the interceptor. Null when there is no session.
  String? get accessToken => switch (state) {
    SessionActive(:final session) => session.accessToken,
    _ => null,
  };

  /// Rebuilds the session from the stored refresh, when the application
  /// opens.
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
        // The session could not be verified, but the server did not say it
        // was invalid either. **The credential is kept**: without signal
        // nobody can sign in again, so deleting it would make the device
        // useless in the very basement where it is needed most. When the
        // connection comes back, restoring tries again.
        state = SessionAbsent(failure: failure);
        return;
      }
      // The server did say it is no good: expired, revoked or reused.
      await _clear(failure: failure);
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
      state = SessionAbsent(failure: _failureFor(error));
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
      // A partial token expires in minutes. If it ran out, go back to sign-in
      // rather than leave somebody typing codes at a door that already
      // closed.
      if (failure is UnauthorizedFailure) {
        state = SessionAbsent(failure: failure);
      } else {
        state = SessionAwaitingTotp(
          partialToken: current.partialToken,
          failure: failure,
        );
      }
    }
  }

  /// Cancels the second factor and goes back to sign-in.
  void cancelTotp() => state = const SessionAbsent();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // The backend answers with a new session, so changing the password also
    // renews the device's credentials.
    final token = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _adopt(token);
  }

  /// Renews the session. The interceptor uses it on a 401.
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
        message: 'No credential to renew the session',
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

    // The notice destination is unregistered first, and that needs the very
    // session being handed back. On a centre phone this is not tidying up:
    // without this call, the next person to sign in would get the previous
    // one's notices.
    // And symmetrically: failing to unregister cannot trap somebody inside a
    // session they want to close.
    try {
      await ref.read(onSessionEndingProvider)();
    } on Object {
      // The window this opens closes by itself: with no session nobody looks
      // at notices, and the next sign-in reassigns the token to whoever it
      // belongs to.
    }

    await _repository.logout(refreshToken);
    await _clear();
  }

  /// Leaves the device without a session when renewal fails.
  ///
  /// It does not unregister the notice destination, and it cannot: that call
  /// needs a valid session, which is exactly what was just lost. The token
  /// stays registered until somebody signs in, and signing in reassigns it.

  Future<void> expire() => _clear(
    failure: const UnauthorizedFailure(
      code: 'UNAUTHORIZED',
      message: 'Session expired',
    ),
  );

  /// Adopts the token as the active session.
  ///
  /// [identifyUser] is only true where the person may have changed: signing in,
  /// and passing the second factor. Restoring and renewing start from a stored
  /// refresh, and a refresh does not turn into somebody else.
  Future<void> _adopt(Token token, {bool identifyUser = false}) async {
    // The backend rotates the refresh on every use: store the new one, or the
    // previous one is left useless on the device.
    if (token.refreshToken case final refresh?) {
      await _storage.writeRefreshToken(refresh);
    }

    final userId = identifyUser
        ? await _adoptIdentity(token.accessToken)
        : await _storage.readUserId();

    // A token with no role comes from a renewal, and a renewal does not say
    // who anybody is: it has to be asked. If it cannot be — no signal, server
    // down — the session opens anyway without a role, which is the safe
    // direction: it offers less, never more, and the server still decides on
    // every call.
    final identity = token.centerRole == null
        ? await _identity(token.accessToken)
        : null;

    state = SessionActive(
      Session.fromToken(token, userId: userId, identity: identity),
    );

    // Registering the notice destination goes **after** the session is
    // exposed: the endpoint requires it, and the client with a session takes
    // its token from this state. Only on real sign-ins — not on restore or
    // renewal — because registering is idempotent and whoever reopens the
    // application is still the destination they registered when they signed
    // in.
    if (identifyUser) {
      // Wrapped because **nothing about notices may stop somebody signing
      // in**. The registrar already swallows its own network failures; this
      // covers the rest — the service not starting, no Google services — and
      // leaves the session open anyway. You can work without notices; you
      // cannot work without a session.
      try {
        await ref.read(onSessionStartedProvider)();
      } on Object {
        // It is retried next session, and registering is idempotent.
      }
    }
  }

  /// Who they are, without deciding anything about the cache.
  ///
  /// Deliberately separate from [_adoptIdentity]: that one resolves identity
  /// **and** decides whether the read model survives, because the person may
  /// have changed. Here they cannot have: this comes from a refresh stored on
  /// this same device, so asking only fills in what the token did not carry.
  Future<UserOut?> _identity(String accessToken) async {
    try {
      return await _repository.me(accessToken);
    } on Object {
      return null;
    }
  }

  /// Resolves who signed in, and decides whether the previous shift's cache
  /// survives.
  ///
  /// It is cleared unless the identity matches the stored one. The two cases
  /// that look excessive are the ones that matter: a fresh install has no
  /// stored identity and clears an empty database, which costs nothing; and if
  /// the server does not answer who they are, it is cleared anyway. Failing
  /// towards deletion is the only safe direction, because the alternative is
  /// showing one person's data to the next one who picks up the centre's phone.
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

  Future<void> _clear({ApiFailure? failure}) async {
    await _storage.clear();
    state = SessionAbsent(failure: failure);
  }

  ApiFailure _failureFor(Object error) => ApiErrorMapper.fromAny(error);
}
