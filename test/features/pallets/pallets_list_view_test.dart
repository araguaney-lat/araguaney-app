import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
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
  }) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, pallets));
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
          home: PalletsListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the header splits open from closed, which decide what to do', (
    tester,
  ) async {
    // Una abierta admite cajas; una cerrada espera un envío. Son dos trabajos
    // distintos y por eso van separados en vez de sumados.
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
    // Un estado sin tarimas no se ofrece: un filtro que vacía la pantalla sin
    // avisar es peor que no tenerlo.
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
    // La cerrada enseña su estado en español, no la clave del servidor.
    expect(find.text('Cerrada'), findsWidgets);
    expect(find.text('CLOSED'), findsNothing);
  });

  testWidgets('offline it is not offered at all', (tester) async {
    // Cerrar decide sobre estado compartido que otro dispositivo puede estar
    // cambiando, igual que sellar una caja.
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
    // Recién abierta no tiene peso, ni altura, ni fecha de cierre. Un
    // subtítulo vacío deja un hueco que se lee como algo roto.
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
