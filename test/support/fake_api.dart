import 'package:dio/dio.dart';

import 'fake_http_adapter.dart';

/// `Dio` sin interceptores contra un adaptador falso.
///
/// Los repositorios se prueban contra el cliente generado de verdad, no contra
/// un doble suyo: así la serialización del contrato entra en la prueba, que es
/// justo donde un cambio del backend rompería en producción.
Dio fakeDio(FakeHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = adapter;

/// Adaptador que simula un sótano sin señal.
class OfflineHttpAdapter extends FakeHttpAdapter {
  OfflineHttpAdapter()
    : super(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sin conexión',
        ),
      );
}
