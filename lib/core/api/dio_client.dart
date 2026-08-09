import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_error_mapper.dart';

/// Construye el `Dio` que usa toda la aplicación.
///
/// Ninguna pantalla crea su propio cliente: la URL base, los tiempos de espera
/// y la traducción de errores se deciden una vez y aquí. Es el equivalente al
/// `apiFetch` centralizado de la aplicación web.
abstract final class DioClient {
  /// Margen para una red de centro de acopio, no para una oficina con fibra.
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
          // Identifica al cliente en los registros del servidor. Saber qué
          // versión hizo una petición es la diferencia entre diagnosticar un
          // problema y adivinarlo.
          'User-Agent': 'AraguaneyApp/$appVersion (${AppConfig.flavor.name})',
        },
      ),
    );

    dio.interceptors
      ..addAll(interceptors)
      // El traductor va al final: convierte cualquier DioException en un
      // ApiFailure antes de que salga de esta capa, para que ninguna pantalla
      // tenga que conocer dio.
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
