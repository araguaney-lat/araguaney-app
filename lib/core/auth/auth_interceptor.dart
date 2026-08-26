import 'package:dio/dio.dart';

/// Puts the access token on every request and renews the session when the
/// server answers 401.
///
/// Three details that look like implementation and are not:
///
/// - **One renewal at a time.** Opening a screen fires several requests at
///   once; if the token expired, they all get a 401 at nearly the same moment.
///   Without this care each one would ask for its own renewal, and since the
///   backend **rotates** the refresh on every use, the second would arrive with
///   an already-revoked token: the server would read that as reuse, revoke the
///   family and throw out whoever was working. They all wait on the same
///   renewal.
/// - **One retry.** If a 401 comes back after renewing, the token is not the
///   problem and retrying would be a loop.
/// - **The session endpoints are not renewed.** A 401 from `login` or
///   `refresh` is the answer, not an expired token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.readAccessToken,
    required this.refreshSession,
    required this.onSessionExpired,
    required this.retryClient,
  });

  /// The current token, or null when there is no session.
  final String? Function() readAccessToken;

  /// Renews and returns the new access token. Throws if it cannot renew.
  final Future<String> Function() refreshSession;

  /// Called when the renewal fails and the local session stops being any
  /// use.
  final Future<void> Function() onSessionExpired;

  /// A client without the session interceptor, for resending the original
  /// request.
  final Dio retryClient;

  /// A mark on the request so it is not retried twice.
  static const _retriedFlag = 'auth_retried';

  static const _pathsWithoutSession = {
    '/v1/auth/login',
    '/v1/auth/refresh',
    '/v1/auth/totp/challenge',
    '/v1/auth/forgot-password',
    '/v1/auth/reset-password',
  };

  Future<String>? _inFlightRefresh;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isSessionEndpoint(options.path)) {
      final token = readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldTryRefresh =
        err.response?.statusCode == 401 &&
        !_isSessionEndpoint(request.path) &&
        request.extra[_retriedFlag] != true;

    if (!shouldTryRefresh) {
      handler.next(err);
      return;
    }

    final String accessToken;
    try {
      accessToken = await (_inFlightRefresh ??= _refreshOnce());
    } on Object {
      await onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      final retried = await retryClient.fetch<dynamic>(
        request
          ..extra[_retriedFlag] = true
          ..headers['Authorization'] = 'Bearer $accessToken',
      );
      handler.resolve(retried);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String> _refreshOnce() async {
    try {
      return await refreshSession();
    } finally {
      // Released whatever happens: leaving it in place would have the
      // application waiting forever on a dead renewal after one transient
      // failure.
      _inFlightRefresh = null;
    }
  }

  bool _isSessionEndpoint(String path) =>
      _pathsWithoutSession.any(path.endsWith);
}
