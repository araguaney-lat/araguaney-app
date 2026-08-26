/// Decides whether a read from the camera deserves attention.
///
/// In continuous mode the camera reads the same label many times a second while
/// the phone is held over it. Without this, holding the device over a box would
/// fire a burst of requests for a single code; the server rate-limits the
/// public records and that burst would spend the allowance reading the same
/// thing forty times.
///
/// A different code goes through immediately: whoever scans a row of boxes has
/// no reason to wait between one and the next.
class ScanThrottle {
  ScanThrottle({Duration? window, DateTime Function()? now})
    : _window = window ?? const Duration(seconds: 3),
      _now = now ?? DateTime.now;

  final Duration _window;
  final DateTime Function() _now;

  String? _lastCode;
  DateTime? _lastAt;

  /// Whether [code] should be processed. It records the read when it accepts
  /// it.
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

  /// Forgets the last read. It is called on coming back from a record, so that
  /// pointing at the same label again opens it once more.
  void reset() {
    _lastCode = null;
    _lastAt = null;
  }
}
