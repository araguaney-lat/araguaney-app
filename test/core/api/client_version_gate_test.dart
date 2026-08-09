import 'package:araguaney_app/core/api/client_version_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientVersionGate', () {
    test('blocks a version below the minimum supported', () {
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '1.0.0',
          minSupportedVersion: '1.2.0',
          latestVersion: '1.5.0',
        ),
        ClientVersionStatus.updateRequired,
      );
    });

    test('the minimum supported version itself is not blocked', () {
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '1.2.0',
          minSupportedVersion: '1.2.0',
          latestVersion: '1.2.0',
        ),
        ClientVersionStatus.current,
      );
    });

    test('reports an available update without blocking', () {
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '1.3.0',
          minSupportedVersion: '1.2.0',
          latestVersion: '1.5.0',
        ),
        ClientVersionStatus.updateAvailable,
      );
    });

    test('a version ahead of the published latest is current', () {
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '2.0.0',
          minSupportedVersion: '1.2.0',
          latestVersion: '1.5.0',
        ),
        ClientVersionStatus.current,
      );
    });

    test('build metadata does not affect precedence', () {
      // pubspec.yaml produce "1.2.0+37"; el "+37" no participa en la comparación.
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '1.2.0+37',
          minSupportedVersion: '1.2.0',
          latestVersion: '1.2.0',
        ),
        ClientVersionStatus.current,
      );
    });

    test('fails open when the server publishes nothing usable', () {
      // Un fallo de la comprobación no puede dejar sin trabajar a un centro.
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '1.0.0',
          minSupportedVersion: null,
          latestVersion: null,
        ),
        ClientVersionStatus.unknown,
      );
    });

    test('fails open on an unparseable server value', () {
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '1.0.0',
          minSupportedVersion: 'not-a-version',
          latestVersion: null,
        ),
        ClientVersionStatus.unknown,
      );
    });

    test('fails open on an unparseable installed version', () {
      expect(
        ClientVersionGate.evaluate(
          currentVersion: '',
          minSupportedVersion: '1.0.0',
          latestVersion: '1.0.0',
        ),
        ClientVersionStatus.unknown,
      );
    });
  });
}
