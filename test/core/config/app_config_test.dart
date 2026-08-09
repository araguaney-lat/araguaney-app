import 'package:araguaney_app/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('defaults to dev flavor when APP_FLAVOR is not provided', () {
      // Sin --dart-define en el entorno de test, aplica el default.
      expect(AppConfig.flavor, AppFlavor.dev);
    });

    test('push is enabled outside the foss flavor', () {
      expect(AppConfig.pushEnabled, isTrue);
    });

    test('api base url has a local default for development', () {
      expect(AppConfig.apiBaseUrl, 'http://localhost:8000');
    });
  });
}
