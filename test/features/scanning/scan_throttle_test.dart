import 'package:araguaney_app/features/scanning/domain/scan_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;

  ScanThrottle buildThrottle() =>
      ScanThrottle(window: const Duration(seconds: 3), now: () => now);

  setUp(() => now = DateTime.utc(2026, 8, 10, 12));

  test('the first read is always accepted', () {
    expect(buildThrottle().accepts('BX-0001'), isTrue);
  });

  test('holding the phone over one label does not fire a burst', () {
    final throttle = buildThrottle();
    throttle.accepts('BX-0001');

    now = now.add(const Duration(milliseconds: 200));

    expect(throttle.accepts('BX-0001'), isFalse);
  });

  test('a different label passes immediately', () {
    // Quien escanea una fila de cajas no debería esperar entre una y la
    // siguiente.
    final throttle = buildThrottle();
    throttle.accepts('BX-0001');

    expect(throttle.accepts('BX-0002'), isTrue);
  });

  test('the same label passes again once the window closes', () {
    final throttle = buildThrottle();
    throttle.accepts('BX-0001');

    now = now.add(const Duration(seconds: 4));

    expect(throttle.accepts('BX-0001'), isTrue);
  });

  test('the window is measured from the last accepted read', () {
    final throttle = buildThrottle();
    throttle.accepts('BX-0001');

    now = now.add(const Duration(seconds: 2));
    expect(throttle.accepts('BX-0001'), isFalse);

    now = now.add(const Duration(seconds: 2));
    // Cuatro segundos desde la lectura aceptada, no desde la rechazada.
    expect(throttle.accepts('BX-0001'), isTrue);
  });

  test('reset lets the same label open again right away', () {
    final throttle = buildThrottle();
    throttle.accepts('BX-0001');

    throttle.reset();

    expect(throttle.accepts('BX-0001'), isTrue);
  });
}
