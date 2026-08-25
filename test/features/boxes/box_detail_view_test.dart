import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/boxes/data/boxes_providers.dart';
import 'package:araguaney_app/features/boxes/data/boxes_repository.dart';
import 'package:araguaney_app/features/boxes/ui/box_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_connectivity.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeConnectivityProbe probe;

  setUp(() {
    db = openTestDatabase();
    probe = FakeConnectivityProbe();
  });

  tearDown(() async {
    await db.close();
    await probe.dispose();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    FakeHttpAdapter? adapter,
    String boxId = 'box-1',
  }) async {
    final http = adapter ?? OfflineHttpAdapter();
    final container = ProviderContainer(
      overrides: [
        connectivityProbeProvider.overrideWithValue(probe),
        boxesRepositoryProvider.overrideWithValue(
          BoxesRepository(
            api: BoxesApi(fakeDio(http)),
            database: db,
            now: () => testNow,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          home: BoxDetailView(boxId: boxId, code: 'CJ-0001'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a cached box reads without any network', (tester) async {
    await db.catalogDao.replaceAll([productTypeRow()]);
    await db.boxesDao.replaceAll([boxRow(status: 'SEALED', quantity: 24)]);

    await pumpDetail(tester);

    expect(find.text('Sellada'), findsOneWidget);
    expect(find.text('24 unidad'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
  });

  testWidgets('a box outside the window is fetched when there is signal', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(200, boxJson(id: 'box-far', quantity: 3)),
    );

    await pumpDetail(tester, adapter: adapter, boxId: 'box-far');

    expect(find.text('3 unidad'), findsOneWidget);
  });

  testWidgets('offline, an uncached box says signal is needed', (tester) async {
    await pumpDetail(tester, boxId: 'box-far');

    expect(
      find.textContaining('Necesitas conexión para consultarla'),
      findsOneWidget,
    );
  });

  testWidgets('with signal, a box the server does not know is not found', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(404, {
        'error': {'code': 'NOT_FOUND', 'message': 'no existe'},
      }),
    );

    await pumpDetail(tester, adapter: adapter, boxId: 'box-far');

    expect(find.text('No encontramos esta caja.'), findsOneWidget);
  });
}
