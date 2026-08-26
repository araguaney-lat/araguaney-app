import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_error_mapper.dart';

/// Builds the `Dio` the whole application uses.
///
/// No screen creates its own client: the base URL, the timeouts and the error
/// translation are decided once, here. It is the equivalent of the web
/// application's central `apiFetch`.
abstract final class DioClient {
  /// Headroom for a collection centre's network, not for an office on fibre.
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  static Dio create({
    required String appVersion,
    List<Interceptor> interceptors = const [],
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: {
          // Identifies the client in the server's logs. Knowing which
          // version made a request is the difference between diagnosing a
          // problem and guessing at it.
          'User-Agent': 'AraguaneyApp/$appVersion (${AppConfig.flavor.name})',
        },
      ),
    );

    dio.interceptors
      ..addAll(interceptors)
      // The translator goes last: it turns any DioException into an
      // ApiFailure before it leaves this layer, so that no screen has to know
      // about dio.
      ..add(
        InterceptorsWrapper(
          onError: (error, handler) => handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiErrorMapper.fromDioException(error),
            ),
          ),
        ),
      );

    return dio;
  }
}
