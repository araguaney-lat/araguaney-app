import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptador HTTP falso para probar interceptores sin red.
///
/// Se prefiere sobre un doble de `Dio` completo porque deja intacta la cadena
/// real de interceptores: lo que se prueba es el comportamiento de dio con
/// nuestro código dentro, no una imitación de dio.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  /// Recibe la petición y decide con qué responder.
  final FakeResponse Function(RequestOptions options) handler;

  /// Todas las peticiones que pasaron, en orden.
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

  /// Permite solapar peticiones concurrentes en las pruebas de renovación
  /// única.
  final Duration? delay;
}
