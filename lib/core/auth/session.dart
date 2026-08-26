import '../api/api_failure.dart';

import '../api/generated/models/token.dart';
import '../api/generated/models/user_out.dart';

/// The active session of somebody operating.
///
/// It is immutable: renewing the token produces a new session and never changes
/// the existing one. That way, anybody reading the session during a renewal
/// never sees a half-written state.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.userId,
    required this.centerId,
    required this.centerRole,
    required this.mustChangePassword,
    required this.mustAcceptTerms,
  });

  /// The token carries no identity, so [userId] is resolved separately and
  /// injected here. It is null when who they are could not be confirmed.
  ///
  /// Identity comes from the token, and from [identity] when the token does not
  /// carry it.
  ///
  /// `POST /v1/auth/refresh` answers with the tokens alone: no centre role and
  /// no centre. Restoring the session when the application opens goes through
  /// there, so without this filling in, somebody coordinating a centre came
  /// back as volunteering on every restart — no role, none of their actions —
  /// until they signed in again.
  factory Session.fromToken(Token token, {String? userId, UserOut? identity}) =>
      Session(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        role: token.role ?? identity?.role,
        userId: userId,
        centerId: token.centerId ?? identity?.centerId,
        centerRole: token.centerRole ?? identity?.centerRole,
        mustChangePassword: token.mustChangePassword,
        mustAcceptTerms: token.mustAcceptTerms,
      );

  final String accessToken;
  final String? refreshToken;

  /// Who opened the session. It is the key the cache is scoped by and, from
  /// the next phase on, the capture queue too.
  final String? userId;

  /// The boilerplate's platform role: `user`, `admin` or `superadmin`.
  final String? role;

  /// The centre they belong to. Null for a national administration, which sees
  /// everything.
  final String? centerId;

  /// The domain role: `volunteer`, `coordinator` or `national_admin`.
  final String? centerRole;

  /// The server requires the password to be changed before operating.
  final bool mustChangePassword;

  /// The server asks for the terms to be accepted. It blocks nothing on the
  /// backend, so it is kept here as a fact rather than as a gate.
  final bool mustAcceptTerms;

  /// The offline capture queue is per user, and on a shared device the centre
  /// is part of that identity.
  Session copyWith({String? accessToken, String? refreshToken}) => Session(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    role: role,
    userId: userId,
    centerId: centerId,
    centerRole: centerRole,
    mustChangePassword: mustChangePassword,
    mustAcceptTerms: mustAcceptTerms,
  );
}

/// The state of the session on the device.
sealed class SessionState {
  const SessionState();
}

/// Not known yet: the secure store is being read at start-up.
class SessionRestoring extends SessionState {
  const SessionRestoring();
}

/// There is no session. [failure] says why, when there is a why.
///
/// It carries the failure rather than a sentence: writing one here would make
/// the controller — which has no context — pick a language, and this
/// application has more than one. The screen, which does have context, writes
/// it with `loginFailureMessage`.
class SessionAbsent extends SessionState {
  const SessionAbsent({this.failure});

  final ApiFailure? failure;
}

/// The credentials are right and the second factor is missing.
///
/// The partial token lives in memory only and expires in minutes: it is not a
/// session and it is not persisted.
class SessionAwaitingTotp extends SessionState {
  const SessionAwaitingTotp({required this.partialToken, this.failure});

  final String partialToken;
  final ApiFailure? failure;
}

/// There is a session. If [Session.mustChangePassword] is true, the interface
/// puts the password change in the way before letting anybody operate.
class SessionActive extends SessionState {
  const SessionActive(this.session);

  final Session session;
}
