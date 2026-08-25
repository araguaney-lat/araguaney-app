import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/pallets/data/pallets_providers.dart';
import 'package:araguaney_app/features/pallets/ui/pallet_detail_view.dart';
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

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester, {
    required bool canOperate,
    required bool offline,
    Map<String, Object?>? pallet,
  }) async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, pallet ?? palletDetailJson()),
    );
    final container = ProviderContainer(
      overrides: [
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
          home: PalletDetailView(palletId: 'pallet-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('coordination with signal can add boxes and close', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      canOperate: true,
      offline: false,
      pallet: palletDetailJson(boxes: [boxJson(code: 'BX-0007')]),
    );

    final scan = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Agregar cajas'),
    );
    expect(scan.onPressed, isNotNull);
    expect(find.text('TM-0001'), findsOneWidget);
    expect(find.text('BX-0007'), findsOneWidget);
    expect(find.byTooltip('Quitar de la tarima'), findsOneWidget);
  });

  testWidgets('offline the actions are disabled and the reason is stated', (
    tester,
  ) async {
    await pumpDetail(tester, canOperate: true, offline: true);

    expect(
      find.textContaining('Armar una tarima necesita conexión'),
      findsOneWidget,
    );
    final scan = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Agregar cajas'),
    );
    expect(scan.onPressed, isNull);
  });

  testWidgets('a volunteer is told whose job this is', (tester) async {
    // El backend exige coordinación y sigue siendo quien decide; esto solo
    // evita ofrecer un botón que va a responder 403.
    await pumpDetail(tester, canOperate: false, offline: false);

    expect(find.textContaining('cosa de la coordinación'), findsOneWidget);
  });

  testWidgets('a closed pallet takes no more boxes', (tester) async {
    await pumpDetail(
      tester,
      canOperate: true,
      offline: false,
      pallet: {
        ...palletDetailJson(status: 'closed'),
        'closed_at': testNow.toIso8601String(),
      },
    );

    expect(find.textContaining('ya está cerrada'), findsOneWidget);
    final scan = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Agregar cajas'),
    );
    expect(scan.onPressed, isNull);
    // Y tampoco se puede quitar ninguna de las que lleva.
    expect(find.byTooltip('Quitar de la tarima'), findsNothing);
  });
}
