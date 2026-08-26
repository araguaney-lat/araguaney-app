import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/db/tables/queued_captures_table.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_sync.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/intake/domain/box_draft_input.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';
import 'package:araguaney_app/features/intake/ui/pending_captures_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late CaptureQueueRepository queue;

  setUp(() async {
    db = openTestDatabase();
    queue = CaptureQueueRepository(database: db, now: () => testNow);
    await db.catalogDao.replaceAll([
      productTypeRow(id: 'pt-1', displayName: 'Paracetamol 500 mg'),
    ]);
  });

  tearDown(() => db.close());

  IntakeDraft draftWith({String captureId = 'capture-1', int quantity = 240}) =>
      IntakeDraft(captureId: captureId).addBox(
        BoxDraftInput(
          productType: productTypeRow(id: 'pt-1'),
          quantity: quantity,
          unit: 'unidad',
        ),
      );

  /// The queue is real — in-memory SQLite — because half the errors of this
  /// layer live in the transactions and not in the screen.
  Future<void> pumpPending(
    WidgetTester tester, {
    FakeHttpAdapter? adapter,
  }) async {
    final dio = fakeDio(
      adapter ?? FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
    );
    final container = ProviderContainer(
      overrides: [
        // The database has to be the test's: `boxCodeRepositoryProvider` is not
        // replaced here — the reserved codes are part of what the screen counts
        // — and without this it would open the device's real database.
        appDatabaseProvider.overrideWithValue(db),
        currentUserIdProvider.overrideWithValue('user-1'),
        captureQueueRepositoryProvider.overrideWithValue(queue),
        captureQueueSyncProvider.overrideWithValue(
          CaptureQueueSync(
            api: IntakesApi(dio),
            database: db,
            now: () => testNow,
          ),
        ),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(api: ProductTypesApi(dio), database: db),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PendingCapturesView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Parks a capture as the server would: refusing it over a rule.
  ///
  /// It goes inside `runAsync` because the body of a `testWidgets` runs with a
  /// fake clock: a dio request awaited there never advances, and the test hangs
  /// without ever getting as far as failing.
  Future<void> park(WidgetTester tester, String message) async {
    await queue.enqueue(draft: draftWith(), userId: 'user-1');
    await tester.runAsync(
      () => CaptureQueueSync(
        api: IntakesApi(
          fakeDio(
            FakeHttpAdapter(
              (_) => FakeResponse(422, {
                'error': {'code': 'SHELF_LIFE_TOO_SHORT', 'message': message},
              }),
            ),
          ),
        ),
        database: db,
        now: () => testNow,
      ).flush('user-1'),
    );
  }

  testWidgets('the screen says what waiting means', (tester) async {
    await pumpPending(tester);

    expect(find.text('Pendientes de envío'), findsOneWidget);
    expect(find.text('Nada se pierde: todo espera aquí'), findsOneWidget);
  });

  testWidgets('the strip counts what there is to work without signal', (
    tester,
  ) async {
    await queue.enqueue(draft: draftWith(), userId: 'user-1');

    await pumpPending(tester);

    expect(find.text('Productos descargados'), findsOneWidget);
    expect(find.text('Códigos apartados'), findsOneWidget);
    expect(find.text('Capturas en cola'), findsOneWidget);
    // One product in the catalogue, no reserved code, one capture in the
    // queue.
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('a queued capture lists what is inside it', (tester) async {
    await queue.enqueue(draft: draftWith(), userId: 'user-1');

    await pumpPending(tester);

    expect(find.text('· Paracetamol 500 mg — 240 unidad'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('one still waiting is not asked about', (tester) async {
    // It retries by itself as soon as there is a network: nobody has to decide
    // anything.
    await queue.enqueue(draft: draftWith(), userId: 'user-1');

    await pumpPending(tester);

    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Descartar'), findsNothing);
  });

  testWidgets('a rejected one shows the reason and both decisions', (
    tester,
  ) async {
    await park(tester, 'La caducidad no alcanza el mínimo de la campaña');

    await pumpPending(tester);

    expect(find.text('Rechazada'), findsOneWidget);
    expect(
      find.text('La caducidad no alcanza el mínimo de la campaña'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);
  });

  testWidgets('retrying puts it back in the queue and sends it', (
    tester,
  ) async {
    await park(tester, 'La caducidad no alcanza el mínimo de la campaña');
    final accepted = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));

    await pumpPending(tester, adapter: accepted);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    // With the same capture key, so retrying cannot duplicate.
    final body = accepted.requests.single.data as Map<String, dynamic>;
    expect(body['capture_id'], 'capture-1');
    expect(await db.captureQueueDao.findById('capture-1'), isNull);
  });

  testWidgets('retrying something still refused parks it again', (
    tester,
  ) async {
    await park(tester, 'La caducidad no alcanza el mínimo de la campaña');
    final refused = FakeHttpAdapter(
      (_) => FakeResponse(422, {
        'error': {
          'code': 'SHELF_LIFE_TOO_SHORT',
          'message': 'La caducidad no alcanza el mínimo de la campaña',
        },
      }),
    );

    await pumpPending(tester, adapter: refused);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    // It stays in the queue with its reason: retrying discards nothing.
    final row = await db.captureQueueDao.findById('capture-1');
    expect(row?.status, QueuedCaptureStatus.rejected);
    expect(
      row?.lastFailureMessage,
      'La caducidad no alcanza el mínimo de la campaña',
    );
  });

  testWidgets('discarding asks first and names what is being thrown away', (
    tester,
  ) async {
    await park(tester, 'La caducidad no alcanza el mínimo de la campaña');

    await pumpPending(tester);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Descartar esta captura?'), findsOneWidget);
    expect(find.textContaining('Paracetamol 500 mg'), findsWidgets);

    await tester.tap(find.text('Conservar'));
    await tester.pumpAndSettle();

    expect(await db.captureQueueDao.findById('capture-1'), isNotNull);
  });

  testWidgets('an empty queue says so', (tester) async {
    await pumpPending(tester);

    expect(find.textContaining('No hay capturas esperando'), findsOneWidget);
  });
}
