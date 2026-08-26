import 'package:dio/dio.dart';

import '../api/api_error_mapper.dart';
import '../api/api_failure.dart';
import '../api/generated/models/token.dart';
import '../api/generated/models/user_out.dart';

/// The outcome of a sign-in attempt.
sealed class LoginResult {
  const LoginResult();
}

/// The credentials are right and there is no second factor: there is a
/// session.
class LoginSucceeded extends LoginResult {
  const LoginSucceeded(this.token);

  final Token token;
}

/// The credentials are right and the second-factor code is missing.
class LoginNeedsTotp extends LoginResult {
  const LoginNeedsTotp(this.partialToken);

  final String partialToken;
}

/// Access to the backend's session endpoints.
///
/// Nearly everything goes through the generated client. Signing in cannot, and
/// the reason has changed: the backend does declare its two outcomes — `Token`
/// on 200 and `TotpPending` on 202 — but a typed method cannot return two types
/// depending on the HTTP status. The generator picks one and discards the
/// other.
///
/// So this request is made by hand and **the body is read with the generated
/// models**: the shape still comes from the contract rather than from a
/// hand-written copy that would drift out of sync. See `api/README.md`.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Sign-in's other possible answer: the backend replies 202 with a partial
  /// token when the account has a second factor.
  static const _totpPendingStatus = 202;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    // The endpoint takes the standard OAuth2 form, not JSON.
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {'username': username.trim(), 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    final body = response.data;
    if (body == null) {
      throw const UnknownFailure(
        code: 'EMPTY_LOGIN_RESPONSE',
        message: 'The server returned no session',
      );
    }

    if (response.statusCode == _totpPendingStatus ||
        body['requires_totp'] == true) {
      final partial = body['partial_token'] as String?;
      if (partial == null) {
        throw const UnknownFailure(
          code: 'MISSING_PARTIAL_TOKEN',
          message:
              'The server asked for a second factor without handing over the token',
        );
      }
      return LoginNeedsTotp(partial);
    }

    return LoginSucceeded(Token.fromJson(body));
  }

  Future<Token> totpChallenge({
    required String partialToken,
    required String code,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/totp/challenge',
      data: {'partial_token': partialToken, 'code': code.trim()},
    );
    return Token.fromJson(response.data!);
  }

  /// Who the person behind this token is.
  ///
  /// The header is set by hand and it goes through the client **without a
  /// session**: identity has to be resolved *before* the session is exposed to
  /// the rest of the application, and the client with a session takes its token
  /// from a session that does not exist yet. This is what decides whether the
  /// previous shift's cache is cleared.
  Future<UserOut> me(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return UserOut.fromJson(response.data!);
  }

  /// Renews the session. The backend **rotates** the refresh on every use, so
  /// the caller has to store the one that comes back: the previous one is
  /// revoked, and reusing it is what gives a theft away.
  Future<Token> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return Token.fromJson(response.data!);
  }

  Future<Token> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/auth/me/password',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    );
    return Token.fromJson(response.data!);
  }

  /// Signs out on the server. It never propagates a failure: if the network
  /// fails, the local session is cleared anyway. Leaving somebody inside the
  /// application because the server did not answer would be the worst possible
  /// outcome.
  Future<void> logout(String? refreshToken) async {
    try {
      await _dio.post<void>(
        '/v1/auth/logout',
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (error) {
      final failure = ApiErrorMapper.fromDioException(error);
      // Swallowed on purpose: the local clearing happens in the controller.
      assert(() {
        // ignore: avoid_print
        print('Remote logout failed (${failure.code}); closing locally');
        return true;
      }());
    }
  }
}
