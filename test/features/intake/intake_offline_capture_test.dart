import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/catalog/data/catalog_providers.dart';
import 'package:araguaney_app/features/catalog/data/catalog_repository.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/intake/data/intake_repository.dart';
import 'package:araguaney_app/features/intake/ui/intake_form_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_connectivity.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fake_queue.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeConnectivityProbe probe;
  late FakeCaptureQueue queue;
  late FakeBoxCodes codes;

  setUp(() async {
    db = openTestDatabase();
    probe = FakeConnectivityProbe();
    queue = FakeCaptureQueue(db);
    codes = FakeBoxCodes(database: db);
    // The catalogue is real: choosing a product without signal is exactly what
    // phase 03 left working.
    await db.catalogDao.replaceAll([productTypeRow()]);
  });

  tearDown(() async {
    await db.close();
    await probe.dispose();
  });

  Future<ProviderContainer> pumpForm(
    WidgetTester tester,
    FakeHttpAdapter adapter, {
    required bool offline,
  }) async {
    final dio = fakeDio(adapter);
    final container = ProviderContainer(
      overrides: [
        writeCenterIdProvider.overrideWithValue(null),
        captureIdGeneratorProvider.overrideWithValue(() => 'capture-fixed'),
        currentUserIdProvider.overrideWithValue('user-1'),
        connectivityProbeProvider.overrideWithValue(probe),
        captureQueueRepositoryProvider.overrideWithValue(queue),
        boxCodeRepositoryProvider.overrideWithValue(codes),
        intakeRepositoryProvider.overrideWithValue(
          IntakeRepository(IntakesApi(dio)),
        ),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(api: ProductTypesApi(dio), database: db),
        ),
        myCampaignsProvider.overrideWith((ref) async => []),
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
          home: IntakeFormView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> addBox(WidgetTester tester) async {
    await tester.tap(find.text('Añadir caja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir producto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol 500 mg'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Cantidad'), '5');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unidad'),
      'caja',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('with no signal the capture is queued, not attempted', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
    await pumpForm(tester, adapter, offline: true);
    await addBox(tester);

    await submit(tester);

    expect(adapter.requests, isEmpty);
    expect(queue.enqueued.single.userId, 'user-1');
    expect(queue.enqueued.single.draft.captureId, 'capture-fixed');
    expect(find.text('Captura guardada'), findsOneWidget);
  });

  testWidgets('a queued box takes a reserved code so it can be labelled now', (
    tester,
  ) async {
    codes.pool.add('BX-RESERVED');
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
      offline: true,
    );
    await addBox(tester);

    await submit(tester);

    expect(queue.enqueued.single.draft.boxes.single.code, 'BX-RESERVED');
    expect(codes.pool, isEmpty);
    expect(find.text('BX-RESERVED'), findsOneWidget);
  });

  testWidgets('running out of codes does not stop the capture', (tester) async {
    // Losing what was captured would be far worse than being left without a
    // label.
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
      offline: true,
    );
    await addBox(tester);

    await submit(tester);

    expect(queue.enqueued, hasLength(1));
    expect(queue.enqueued.single.draft.boxes.single.code, isNull);
    expect(find.textContaining('quedó sin código'), findsOneWidget);
  });

  testWidgets('the network dropping mid-send queues instead of losing it', (
    tester,
  ) async {
    await pumpForm(tester, OfflineHttpAdapter(), offline: false);
    await addBox(tester);

    await submit(tester);

    expect(find.text('Captura guardada'), findsOneWidget);
    expect(queue.enqueued, hasLength(1));
  });

  testWidgets('with signal nothing is queued: the capture travels now', (
    tester,
  ) async {
    // Parity with phase 05: the queue changes *when* a capture is sent, never
    // *what* it contains nor how the application behaves with signal.
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
    await pumpForm(tester, adapter, offline: false);
    await addBox(tester);

    await submit(tester);

    expect(adapter.requests, hasLength(1));
    expect(find.text('Captura registrada'), findsOneWidget);
    expect(queue.enqueued, isEmpty);
  });

  testWidgets('a business rejection with signal is not queued either', (
    tester,
  ) async {
    // Queueing something the server has already refused would be retrying it
    // forever.
    final adapter = FakeHttpAdapter(
      (_) => FakeResponse(422, {
        'error': {'code': 'RULE', 'message': 'La campaña no acepta esto'},
      }),
    );
    await pumpForm(tester, adapter, offline: false);
    await addBox(tester);

    await submit(tester);

    expect(find.text('La campaña no acepta esto'), findsOneWidget);
    expect(queue.enqueued, isEmpty);
  });
}
