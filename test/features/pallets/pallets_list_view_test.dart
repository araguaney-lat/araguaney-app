import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/pallets/data/pallets_providers.dart';
import 'package:araguaney_app/features/pallets/ui/pallets_list_view.dart';
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

  Future<void> pumpList(
    WidgetTester tester, {
    required List<Map<String, Object?>> pallets,
    bool canOperate = true,
    bool offline = false,
    String? workingCenterId,
  }) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, pallets));
    final container = ProviderContainer(
      overrides: [
        writeCenterIdProvider.overrideWithValue(workingCenterId),
        connectivityProbeProvider.overrideWithValue(probe),
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        canOperatePalletsProvider.overrideWithValue(canOperate),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PalletsListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a working centre hides the other centres\' pallets', (
    tester,
  ) async {
    // The server sends a national session every centre's pallets. Coordinating
    // one from another warehouse means deciding about boxes nobody in the room
    // can see.
    await pumpList(
      tester,
      workingCenterId: 'center-1',
      pallets: [
        palletJson(id: 'p-1', code: 'TM-0001'),
        palletJson(id: 'p-2', code: 'TM-0002', centerId: 'center-2'),
      ],
    );

    expect(find.text('TM-0001'), findsOneWidget);
    expect(find.text('TM-0002'), findsNothing);
  });

  testWidgets('the header splits open from closed, which decide what to do', (
    tester,
  ) async {
    // An open one takes boxes; a closed one waits for a shipment. They are two
    // different jobs and that is why they are shown apart instead of added up.
    await pumpList(
      tester,
      pallets: [
        palletJson(id: 'p-1', code: 'TM-0001'),
        palletJson(id: 'p-2', code: 'TM-0002'),
        palletJson(id: 'p-3', code: 'TM-0003', status: 'CLOSED'),
      ],
    );

    expect(find.text('2 abiertas · 1 cerrada'), findsOneWidget);
  });

  testWidgets('each status filter carries its own count', (tester) async {
    await pumpList(
      tester,
      pallets: [
        palletJson(id: 'p-1', code: 'TM-0001'),
        palletJson(id: 'p-2', code: 'TM-0002', status: 'CLOSED'),
      ],
    );

    expect(find.text('Abierta · 1'), findsOneWidget);
    expect(find.text('Cerrada · 1'), findsOneWidget);
    // A state with no pallets is not offered: a filter that empties the screen
    // without warning is worse than not having it.
    expect(find.textContaining('Enviada'), findsNothing);
  });

  testWidgets('only an open pallet offers to be closed', (tester) async {
    await pumpList(
      tester,
      pallets: [
        palletJson(id: 'p-1', code: 'TM-0001'),
        palletJson(id: 'p-2', code: 'TM-0002', status: 'CLOSED'),
      ],
    );

    expect(find.widgetWithText(TextButton, 'Cerrar'), findsOneWidget);
    // The closed one shows its state in Spanish, not the server's key.
    expect(find.text('Cerrada'), findsWidgets);
    expect(find.text('CLOSED'), findsNothing);
  });

  testWidgets('offline it is not offered at all', (tester) async {
    // Closing decides about shared state another device may be changing, just
    // like sealing a box.
    await pumpList(
      tester,
      pallets: [palletJson(id: 'p-1', code: 'TM-0001')],
      offline: true,
    );

    expect(find.widgetWithText(TextButton, 'Cerrar'), findsNothing);
  });

  testWidgets('volunteering is offered neither closing nor creating', (
    tester,
  ) async {
    await pumpList(
      tester,
      pallets: [palletJson(id: 'p-1', code: 'TM-0001')],
      canOperate: false,
    );

    expect(find.widgetWithText(TextButton, 'Cerrar'), findsNothing);
    expect(find.text('Nueva tarima'), findsNothing);
  });

  testWidgets('a pallet with nothing to say yet has no second line', (
    tester,
  ) async {
    // A freshly opened one has no weight, no height and no closing date. An
    // empty subtitle leaves a gap that reads as something broken.
    await pumpList(
      tester,
      pallets: [palletJson(id: 'p-1', code: 'TM-0001')],
    );

    final tile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'TM-0001'),
    );
    expect(tile.subtitle, isNull);
  });

  testWidgets('an empty centre says what a pallet is for', (tester) async {
    await pumpList(tester, pallets: const []);

    expect(find.textContaining('agrupa cajas selladas'), findsOneWidget);
  });
}
