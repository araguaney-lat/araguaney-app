import 'package:araguaney_app/core/config/app_config.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/push/push_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the flavor decides which push service the application gets', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(pushServiceProvider);

    if (AppConfig.pushEnabled) {
      expect(service, isNot(isA<NoopPushService>()));
    } else {
      // Compilado con `APP_FLAVOR=foss`. Esta rama sí lleva Firebase dentro, y
      // por eso lo que se comprueba aquí es que no se usa. Que tampoco esté
      // presente solo lo puede demostrar la rama `foss`, que quita la
      // dependencia — ver `docs/release/foss.md`.
      expect(service, isA<NoopPushService>());
    }
  });
}
