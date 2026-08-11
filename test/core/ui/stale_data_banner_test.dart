import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/ui/stale_data_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_connectivity.dart';

void main() {
  late FakeConnectivityProbe probe;

  setUp(() => probe = FakeConnectivityProbe());
  tearDown(() => probe.dispose());

  final now = DateTime.utc(2026, 8, 10, 12);

  Future<ProviderContainer> pumpBanner(
    WidgetTester tester, {
    DateTime? lastSyncedAt,
    String? lastFailureCode,
  }) async {
    final container = ProviderContainer(
      overrides: [connectivityProbeProvider.overrideWithValue(probe)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: StaleDataBanner(
              lastSyncedAt: lastSyncedAt,
              lastFailureCode: lastFailureCode,
              now: () => now,
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('says nothing while everything is fresh and online', (
    tester,
  ) async {
    final container = await pumpBanner(
      tester,
      lastSyncedAt: now.subtract(const Duration(minutes: 5)),
    );
    container.read(connectivityControllerProvider.notifier).reportReachable();
    await tester.pump();

    expect(find.textContaining('Sin conexión'), findsNothing);
  });

  testWidgets('offline it says how old the data is', (tester) async {
    final container = await pumpBanner(
      tester,
      lastSyncedAt: now.subtract(const Duration(minutes: 12)),
    );
    container.read(connectivityControllerProvider.notifier).reportUnreachable();
    await tester.pump();

    expect(
      find.text('Sin conexión · datos de hace 12 minutos'),
      findsOneWidget,
    );
  });

  testWidgets('offline with nothing downloaded it says so', (tester) async {
    final container = await pumpBanner(tester);
    container.read(connectivityControllerProvider.notifier).reportUnreachable();
    await tester.pump();

    expect(
      find.text('Sin conexión · todavía no se descargó nada'),
      findsOneWidget,
    );
  });

  testWidgets('online but with a failed refresh it still warns', (
    tester,
  ) async {
    final container = await pumpBanner(
      tester,
      lastSyncedAt: now.subtract(const Duration(hours: 2)),
      lastFailureCode: 'INTERNAL_ERROR',
    );
    container.read(connectivityControllerProvider.notifier).reportReachable();
    await tester.pump();

    expect(
      find.text('No se pudo actualizar · datos de hace 2 horas'),
      findsOneWidget,
    );
  });
}
