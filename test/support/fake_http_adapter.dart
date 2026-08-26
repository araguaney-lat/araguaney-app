import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A fake HTTP adapter for testing interceptors without a network.
///
/// It is preferred over a double of the whole `Dio` because it leaves the real
/// interceptor chain intact: what is tested is dio's behaviour with our code
/// inside it, not an imitation of dio.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  /// Receives the request and decides what to answer with.
  final FakeResponse Function(RequestOptions options) handler;

  /// Every request that went through, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = handler(options);
    if (response.delay case final delay?) {
      await Future<void>.delayed(delay);
    }
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(this.statusCode, this.body, {this.delay});

  final int statusCode;
  final Object? body;

  /// Allows concurrent requests to overlap in the single-renewal tests.
  final Duration? delay;
}
