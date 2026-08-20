import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/features/transfers/ui/transfer_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_connectivity.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  late FakeConnectivityProbe probe;

  setUp(() => probe = FakeConnectivityProbe());
  tearDown(() => probe.dispose());

  Future<FakeHttpAdapter> pumpDetail(
    WidgetTester tester, {
    required String status,
    required String myCenterId,
    bool offline = false,
  }) async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(
        200,
        transferJson(
          status: status,
          fromCenterId: 'origin',
          toCenterId: 'dest',
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        connectivityProbeProvider.overrideWithValue(probe),
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        myCenterIdProvider.overrideWithValue(myCenterId),
        isNationalAdminProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final connectivity = container.read(
      connectivityControllerProvider.notifier,
    );
    offline ? connectivity.reportUnreachable() : connectivity.reportReachable();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: TransferDetailView(transferId: 'transfer-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return adapter;
  }

  testWidgets('the origin sees approve and reject on a requested one', (
    tester,
  ) async {
    await pumpDetail(tester, status: 'REQUESTED', myCenterId: 'origin');

    expect(find.text('Saliente, desde este centro'), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
    expect(find.text('Recibir'), findsNothing);
  });

  testWidgets('the destination sees only receive, and only in transit', (
    tester,
  ) async {
    await pumpDetail(tester, status: 'IN_TRANSIT', myCenterId: 'dest');

    expect(find.text('Entrante, hacia este centro'), findsOneWidget);
    expect(find.text('Recibir'), findsOneWidget);
    expect(find.text('Aprobar'), findsNothing);
  });

  testWidgets('approving sends the transition to its own endpoint', (
    tester,
  ) async {
    final adapter = await pumpDetail(
      tester,
      status: 'REQUESTED',
      myCenterId: 'origin',
    );

    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.map((r) => r.path),
      contains('/v1/transfers/transfer-1/approve'),
    );
  });

  testWidgets('rejecting asks for a reason before sending it', (tester) async {
    // Es lo único que el otro centro va a leer para entender por qué sus cajas
    // no salieron.
    final adapter = await pumpDetail(
      tester,
      status: 'REQUESTED',
      myCenterId: 'origin',
    );

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Por qué se rechaza?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Las cajas ya salieron');
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
    await tester.pumpAndSettle();

    final rejection = adapter.requests.firstWhere(
      (r) => r.path.endsWith('/reject'),
    );
    expect(
      (rejection.data as Map<String, dynamic>)['reason'],
      'Las cajas ya salieron',
    );
  });

  testWidgets('a closed transfer offers nothing', (tester) async {
    await pumpDetail(tester, status: 'RECEIVED', myCenterId: 'dest');

    expect(find.text('Recibir'), findsNothing);
    expect(find.text('Recibida'), findsOneWidget);
  });

  testWidgets('offline the actions are disabled and the reason is stated', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      status: 'IN_TRANSIT',
      myCenterId: 'dest',
      offline: true,
    );

    expect(find.textContaining('la mueven dos centros'), findsOneWidget);
    final receive = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Recibir'),
    );
    expect(receive.onPressed, isNull);
  });
}
