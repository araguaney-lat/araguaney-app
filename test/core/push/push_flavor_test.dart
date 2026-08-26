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
      // Built with `APP_FLAVOR=foss`. This branch does carry Firebase inside,
      // and that is why what is checked here is that it is not used. That it is
      // not even present can only be proved by the `foss` branch, which drops
      // the dependency — see `docs/release/foss.md`.
      expect(service, isA<NoopPushService>());
    }
  });
}
