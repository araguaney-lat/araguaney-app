import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  late FakeConnectivityProbe probe;
  late ProviderContainer container;

  ProviderContainer containerWith(FakeConnectivityProbe probe) =>
      ProviderContainer(
        overrides: [connectivityProbeProvider.overrideWithValue(probe)],
      );

  setUp(() {
    probe = FakeConnectivityProbe();
    container = containerWith(probe);
  });

  tearDown(() {
    container.dispose();
    probe.dispose();
  });

  ConnectivityStatus statusOf(ProviderContainer container) =>
      container.read(connectivityControllerProvider);

  test('starts unknown: an interface is not proof of a reachable server', () {
    expect(statusOf(container), ConnectivityStatus.unknown);
  });

  test('losing the interface is offline right away', () async {
    statusOf(container);

    probe.emit(hasInterface: false);
    await Future<void>.delayed(Duration.zero);

    expect(statusOf(container), ConnectivityStatus.offline);
  });

  test('regaining the interface goes back to unknown, never online', () async {
    statusOf(container);
    probe.emit(hasInterface: false);
    await Future<void>.delayed(Duration.zero);

    probe.emit(hasInterface: true);
    await Future<void>.delayed(Duration.zero);

    expect(statusOf(container), ConnectivityStatus.unknown);
  });

  test('a request that reached the server is what proves online', () {
    container.read(connectivityControllerProvider.notifier).reportReachable();

    expect(statusOf(container), ConnectivityStatus.online);
  });

  test('a request that never left the device is offline', () {
    container.read(connectivityControllerProvider.notifier).reportUnreachable();

    expect(statusOf(container), ConnectivityStatus.offline);
  });

  test(
    'the initial probe reports offline when there is no interface',
    () async {
      final offlineProbe = FakeConnectivityProbe(initialInterface: false);
      final offlineContainer = containerWith(offlineProbe);
      addTearDown(offlineContainer.dispose);
      addTearDown(offlineProbe.dispose);

      statusOf(offlineContainer);
      await Future<void>.delayed(Duration.zero);

      expect(statusOf(offlineContainer), ConnectivityStatus.offline);
    },
  );

  test(
    'a late initial probe does not demote a session already online',
    () async {
      container.read(connectivityControllerProvider.notifier).reportReachable();

      await Future<void>.delayed(Duration.zero);

      expect(statusOf(container), ConnectivityStatus.online);
    },
  );
}
