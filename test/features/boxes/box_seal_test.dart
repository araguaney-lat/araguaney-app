import 'package:araguaney_app/core/api/generated/clients/boxes_api.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/sync/sync_outcome.dart';
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

  BoxesRepository repositoryOn(FakeHttpAdapter adapter) => BoxesRepository(
    api: BoxesApi(fakeDio(adapter)),
    database: db,
    now: () => testNow,
  );

  group('the repository', () {
    test(
      'sealing writes the state the server returned into the cache',
      () async {
        await db.boxesDao.replaceAll([boxRow(status: 'open')]);
        final sealed = DateTime.utc(2026, 8, 10, 15);
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(200, {
            ...boxJson(status: 'sealed'),
            'sealed_at': sealed.toIso8601String(),
          }),
        );

        final outcome = await repositoryOn(adapter).seal('box-1');

        expect(outcome, isA<SyncSucceeded>());
        final cached = await db.boxesDao.findById('box-1');
        expect(cached?.status, 'sealed');
        expect(cached?.sealedAt, sealed);
      },
    );

    test('a rejected seal leaves the cached box untouched', () async {
      await db.boxesDao.replaceAll([boxRow(status: 'open')]);
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(409, {
          'error': {
            'code': 'BOX_ALREADY_SEALED',
            'message': 'Ya estaba sellada',
          },
        }),
      );

      final outcome = await repositoryOn(adapter).seal('box-1');

      expect(outcome, isA<SyncFailed>());
      expect((await db.boxesDao.findById('box-1'))?.status, 'open');
    });
  });

  group('the screen', () {
    Future<ProviderContainer> pumpDetail(
      WidgetTester tester,
      FakeHttpAdapter adapter,
    ) async {
      final container = ProviderContainer(
        overrides: [
          connectivityProbeProvider.overrideWithValue(probe),
          boxesRepositoryProvider.overrideWithValue(repositoryOn(adapter)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BoxDetailView(boxId: 'box-1', code: 'BX-0001'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('offline, sealing is disabled and the reason is stated', (
      tester,
    ) async {
      await db.boxesDao.replaceAll([boxRow(status: 'open')]);
      final container = await pumpDetail(tester, OfflineHttpAdapter());
      container
          .read(connectivityControllerProvider.notifier)
          .reportUnreachable();
      await tester.pumpAndSettle();

      expect(find.textContaining('Sellar necesita conexión'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Sellar caja'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a box already sealed offers no seal action', (tester) async {
      await db.boxesDao.replaceAll([
        boxRow(status: 'sealed', sealedAt: testNow),
      ]);

      await pumpDetail(
        tester,
        FakeHttpAdapter(
          (_) => FakeResponse(200, {
            ...boxJson(status: 'sealed'),
            'sealed_at': testNow.toIso8601String(),
          }),
        ),
      );

      expect(find.text('Sellar caja'), findsNothing);
    });
  });
}
