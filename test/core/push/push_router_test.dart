import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/push/push_destination.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/routing/push_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fake_push.dart';
import '../../support/fixtures.dart';

void main() {
  late FakePushService push;

  setUp(() => push = FakePushService());
  tearDown(() => push.dispose());

  Future<void> pumpRouter(WidgetTester tester, FakeHttpAdapter adapter) async {
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(push),
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        // The shipment record asks for the role to decide whether to offer
        // raising an incident; with no session, asking brings up the whole
        // tree.
        isCenterCoordinatorProvider.overrideWithValue(false),
        isNationalAdminProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: PushRouter(child: Scaffold(body: Text('inicio'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a risk review notice opens the reviews, marking its own', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, [
        riskReviewJson(id: 'rr-1', intakeId: 'intake-otro'),
        riskReviewJson(
          id: 'rr-2',
          intakeId: 'intake-9',
          reason: 'Caducidad por debajo del mínimo',
        ),
      ]),
    );
    await pumpRouter(tester, adapter);

    push.open(const RiskReviewDestination('intake-9'));
    await tester.pumpAndSettle();

    expect(find.text('Revisiones'), findsOneWidget);
    // The reason is exactly what the notice does not say, and that is why
    // people come here.
    expect(
      find.textContaining('Caducidad por debajo del mínimo'),
      findsOneWidget,
    );
    expect(find.text('La del aviso que abriste'), findsOneWidget);
  });

  testWidgets('a delivered shipment opens its record', (tester) async {
    // The record asks for three things: the shipment, its reception and its
    // incidents.
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/reception')) {
        return FakeResponse(200, receptionJson());
      }
      if (options.path.endsWith('/incidents')) {
        return FakeResponse(200, const []);
      }
      return FakeResponse(200, shipmentJson(reference: 'ENV-77'));
    });
    await pumpRouter(tester, adapter);

    push.open(const ShipmentDeliveredDestination('shipment-4'));
    await tester.pumpAndSettle();

    expect(find.text('ENV-77'), findsOneWidget);
    expect(find.text('Caracas'), findsOneWidget);
    expect(
      adapter.requests.map((r) => r.path),
      contains('/v1/shipments/shipment-4'),
    );
  });

  testWidgets('an unknown notice navigates nowhere', (tester) async {
    // The server composed the text and it has already been shown; opening some
    // arbitrary screen would be worse than opening none.
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, const []));
    await pumpRouter(tester, adapter);

    push.open(const UnknownDestination('message_received'));
    await tester.pumpAndSettle();

    expect(find.text('inicio'), findsOneWidget);
    expect(adapter.requests, isEmpty);
  });
}
