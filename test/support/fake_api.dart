import 'package:dio/dio.dart';

import 'fake_http_adapter.dart';

/// A `Dio` with no interceptors against a fake adapter.
///
/// The repositories are tested against the real generated client, not against a
/// double of it: that way the contract's serialisation is part of the test,
/// which is exactly where a backend change would break in production.
Dio fakeDio(FakeHttpAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = adapter;

/// An adapter that simulates a basement with no signal.
class OfflineHttpAdapter extends FakeHttpAdapter {
  OfflineHttpAdapter()
    : super(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sin conexión',
        ),
      );
}
