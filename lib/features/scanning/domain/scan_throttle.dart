/// Decide si una lectura de la cámara merece atención.
///
/// En modo continuo la cámara lee la misma etiqueta muchas veces por segundo
/// mientras el teléfono está encima. Sin esto, sostener el aparato sobre una
/// caja dispararía una ráfaga de peticiones por un solo código; el servidor
/// limita la frecuencia de las fichas públicas y esa ráfaga la gastaría en
/// leer cuarenta veces lo mismo.
///
/// Un código distinto pasa de inmediato: quien escanea una fila de cajas no
/// tiene por qué esperar entre una y la siguiente.
class ScanThrottle {
  ScanThrottle({Duration? window, DateTime Function()? now})
    : _window = window ?? const Duration(seconds: 3),
      _now = now ?? DateTime.now;

  final Duration _window;
  final DateTime Function() _now;

  String? _lastCode;
  DateTime? _lastAt;

  /// Si [code] debe procesarse. Registra la lectura cuando la acepta.
  bool accepts(String code) {
    final at = _now();
    final repeated =
        code == _lastCode &&
        _lastAt != null &&
        at.difference(_lastAt!) < _window;

    if (repeated) return false;

    _lastCode = code;
    _lastAt = at;
    return true;
  }

  /// Olvida la última lectura. Se llama al volver de una ficha, para que
  /// reapuntar a la misma etiqueta vuelva a abrirla.
  void reset() {
    _lastCode = null;
    _lastAt = null;
  }
}
