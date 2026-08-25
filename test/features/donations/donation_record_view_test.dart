import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/donations/ui/donation_record_view.dart';
import 'package:araguaney_app/features/donations/ui/donations_list_view.dart';
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

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    required FakeHttpAdapter adapter,
    bool offline = false,
    String? workingCenterId,
  }) async {
    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        connectivityProbeProvider.overrideWithValue(probe),
        writeCenterIdProvider.overrideWithValue(workingCenterId),
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
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the list', () {
    testWidgets('what is coming and what arrived are two questions', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [donationJson()]),
      );

      await pump(tester, const DonationsListView(), adapter: adapter);
      expect(adapter.requests.last.queryParameters['incoming'], true);

      await tester.tap(find.text('Recibidas'));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['incoming'], false);
    });
  });

  group('the record', () {
    testWidgets('what the donor declared is shown as declared', (tester) async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, donationJson()));

      await pump(
        tester,
        const DonationRecordView(code: 'DN-0001'),
        adapter: adapter,
      );

      expect(find.text('Paracetamol 500 mg'), findsOneWidget);
      // What is registered is what arrived, and the screen says so before
      // anybody starts ticking boxes.
      expect(find.textContaining('Marca solo lo que no llegó'), findsOneWidget);
    });

    testWidgets('receiving sends only what was marked', (tester) async {
      final adapter = FakeHttpAdapter(
        (options) => FakeResponse(
          200,
          donationJson(
            items: [
              donationItemJson(id: 'item-1'),
              donationItemJson(id: 'item-2', freeText: 'Agua'),
            ],
          ),
        ),
      );

      await pump(
        tester,
        const DonationRecordView(code: 'DN-0001'),
        adapter: adapter,
        workingCenterId: 'center-7',
      );

      await tester.tap(find.text('Falta').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recibir la donación'));
      await tester.pumpAndSettle();

      final receive = adapter.requests.firstWhere(
        (request) => request.path.endsWith('/receive'),
      );
      final body = receive.data as Map<String, Object?>;
      expect(body['results'], {'item-2': 'MISSING'});
      expect(body['center_id'], 'center-7');
    });

    testWidgets('without signal it explains instead of offering', (
      tester,
    ) async {
      // Two people receiving the same donation from two phones would leave two
      // truths about the same boxes.
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, donationJson()));

      await pump(
        tester,
        const DonationRecordView(code: 'DN-0001'),
        adapter: adapter,
        offline: true,
      );

      expect(find.text('Recibir la donación'), findsNothing);
      expect(find.textContaining('Recibir necesita conexión'), findsOneWidget);
    });

    testWidgets('one already received offers to capture it instead', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, donationJson(status: 'RECEIVED')),
      );

      await pump(
        tester,
        const DonationRecordView(code: 'DN-0001'),
        adapter: adapter,
      );

      expect(find.text('Recibir la donación'), findsNothing);
      expect(find.text('Capturar esta donación'), findsOneWidget);
    });

    testWidgets('an atypical volume is flagged without naming a threshold', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, donationJson(atypicalVolume: true)),
      );

      await pump(
        tester,
        const DonationRecordView(code: 'DN-0001'),
        adapter: adapter,
      );

      expect(find.text('Volumen atípico'), findsOneWidget);
      // The threshold is the server's, and printing it here would be telling
      // somebody exactly when a control fires.
      expect(find.textContaining('kg'), findsNothing);
    });
  });
}
