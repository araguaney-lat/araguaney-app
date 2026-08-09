import 'package:dio/dio.dart';

/// Pone el access token en cada petición y renueva la sesión cuando el servidor
/// contesta 401.
///
/// Tres detalles que parecen de implementación y no lo son:
///
/// - **Una sola renovación a la vez.** Al abrir una pantalla salen varias
///   peticiones juntas; si el token venció, todas reciben 401 casi al mismo
///   tiempo. Sin esta cautela cada una pediría su propia renovación, y como el
///   backend **rota** el refresh en cada uso, la segunda llegaría con un token
///   ya revocado: el servidor lo leería como reutilización, revocaría la
///   familia y expulsaría a quien estaba trabajando. Todas esperan la misma
///   renovación.
/// - **Un solo reintento.** Si tras renovar vuelve un 401, el problema no es el
///   token y reintentar sería un bucle.
/// - **Los endpoints de sesión no se renuevan.** Un 401 de `login` o de
///   `refresh` es la respuesta, no un token vencido.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.readAccessToken,
    required this.refreshSession,
    required this.onSessionExpired,
    required this.retryClient,
  });

  /// Token vigente, o nulo si no hay sesión.
  final String? Function() readAccessToken;

  /// Renueva y devuelve el nuevo access token. Lanza si no se puede renovar.
  final Future<String> Function() refreshSession;

  /// Se llama cuando la renovación falla y la sesión local deja de servir.
  final Future<void> Function() onSessionExpired;

  /// Cliente sin interceptor de sesión, para reenviar la petición original.
  final Dio retryClient;

  /// Marca en la petición para no reintentarla dos veces.
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
      // Se libera pase lo que pase: si se dejara puesto, un fallo transitorio
      // dejaría a la aplicación esperando para siempre una renovación muerta.
      _inFlightRefresh = null;
    }
  }

  bool _isSessionEndpoint(String path) =>
      _pathsWithoutSession.any(path.endsWith);
}
