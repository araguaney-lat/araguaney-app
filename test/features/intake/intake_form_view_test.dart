import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/api/generated/models/box_draft.dart';
import 'package:araguaney_app/core/api/generated/models/campaign_out.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/campaigns/data/campaigns_providers.dart';
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
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late FakeConnectivityProbe probe;

  setUp(() async {
    db = openTestDatabase();
    probe = FakeConnectivityProbe();
    await db.catalogDao.replaceAll([
      productTypeRow(id: 'pt-1', displayName: 'Paracetamol 500 mg'),
      productTypeRow(
        id: 'pt-2',
        displayName: 'Alcohol isopropílico',
        category: 'MEDICAL_SUPPLY',
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
    await probe.dispose();
  });

  Future<void> pumpForm(
    WidgetTester tester,
    FakeHttpAdapter adapter, {
    List<CampaignOut> campaigns = const [],
  }) async {
    final dio = fakeDio(adapter);
    final container = ProviderContainer(
      overrides: [
        writeCenterIdProvider.overrideWithValue(null),
        // The campaign sheet asks for the role in order to offer the record,
        // and asking drags the whole session into this test.
        canBrowseCampaignsProvider.overrideWithValue(false),
        captureIdGeneratorProvider.overrideWithValue(() => 'capture-fixed'),
        intakeRepositoryProvider.overrideWithValue(
          IntakeRepository(IntakesApi(dio)),
        ),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(api: ProductTypesApi(dio), database: db),
        ),
        myCampaignsProvider.overrideWith((ref) async => campaigns),
        // These tests are the previous phase's and go on measuring the same
        // thing: with a connection the capture travels there and then. With no
        // session there is no possible queue, which is exactly what is wanted
        // here.
        currentUserIdProvider.overrideWithValue(null),
        connectivityProbeProvider.overrideWithValue(probe),
      ],
    );
    addTearDown(container.dispose);

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
  }

  /// Adds a box through the product picker, as a person would.
  Future<void> addBox(
    WidgetTester tester, {
    String product = 'Paracetamol 500 mg',
  }) async {
    await tester.tap(find.text('Añadir caja'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elegir producto'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(product));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad'),
      '12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Unidad'),
      'caja',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  testWidgets('a capture with no boxes cannot be sent', (tester) async {
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
    );

    final send = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar'),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('adding a box from the local catalog enables sending', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
    await pumpForm(tester, adapter);

    await addBox(tester);

    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
    expect(find.textContaining('12 caja'), findsOneWidget);
    final send = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Registrar'),
    );
    expect(send.onPressed, isNotNull);
    // The catalogue was searched in the cache: the only possible request would
    // be the submission, which has not happened yet.
    expect(adapter.requests, isEmpty);
  });

  testWidgets('sending carries the boxes and the capture id', (tester) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
    await pumpForm(tester, adapter);
    await addBox(tester);

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['capture_id'], 'capture-fixed');
    // Retrofit leaves the nested objects unserialised until dio encodes them;
    // reading them typed is truer than assuming a map.
    final boxes = (body['boxes'] as List).cast<BoxDraft>();
    expect(boxes.single.quantity, 12);
    expect(boxes.single.unit, 'caja');
    expect(find.text('Captura registrada'), findsOneWidget);
  });

  testWidgets('a server rejection is shown with the server reason', (
    tester,
  ) async {
    await pumpForm(
      tester,
      FakeHttpAdapter(
        (_) => FakeResponse(422, {
          'error': {
            'code': 'SHELF_LIFE_TOO_SHORT',
            'message': 'La caducidad no alcanza el mínimo de la campaña',
          },
        }),
      ),
    );
    await addBox(tester);

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    expect(
      find.text('La caducidad no alcanza el mínimo de la campaña'),
      findsOneWidget,
    );
  });

  testWidgets('when the server asks to identify, the capture is not lost', (
    tester,
  ) async {
    var attempts = 0;
    final adapter = FakeHttpAdapter((_) {
      attempts++;
      return attempts == 1
          ? FakeResponse(422, {
              'error': {
                'code': IntakeRepository.donorRequiredCode,
                'message': 'Esta donación supera el volumen anónimo.',
                'field': 'donor',
              },
            })
          : FakeResponse(201, intakeJson());
    });
    await pumpForm(tester, adapter);
    await addBox(tester);

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    // The server asks; the person records the reason instead of stopping.
    expect(find.text('Falta identificar a quien dona'), findsOneWidget);
    await tester.tap(find.text('No quiso identificarse'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Se fue sin dar datos');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar sin donante'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    final retry = adapter.requests.last.data as Map<String, dynamic>;
    // The same capture key: retrying cannot duplicate inventory.
    expect(retry['capture_id'], 'capture-fixed');
    expect(retry['anonymous_exception_reason'], 'Se fue sin dar datos');
    expect(find.text('Captura registrada'), findsOneWidget);
  });

  testWidgets('the campaign is chosen from the header and travels', (
    tester,
  ) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
    await pumpForm(
      tester,
      adapter,
      campaigns: [campaign(id: 'campaign-1', name: 'Campaña de invierno')],
    );

    expect(find.text('Registrar entrada'), findsOneWidget);
    expect(find.text('Campaña general'), findsOneWidget);

    await tester.tap(find.text('Campaña general'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campaña de invierno'));
    await tester.pumpAndSettle();

    // Changing the header changes the capture, not only what is read on it.
    expect(find.text('Campaña de invierno'), findsOneWidget);
    await addBox(tester);
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['campaign_id'], 'campaign-1');
  });

  testWidgets('the boxes card counts what the entry carries', (tester) async {
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
    );

    expect(find.text('Cajas en la entrada · 0'), findsOneWidget);

    await addBox(tester);

    expect(find.text('Cajas en la entrada · 1'), findsOneWidget);
  });

  testWidgets('the product picker names categories in Spanish', (tester) async {
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
    );

    await tester.tap(find.text('Añadir caja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir producto'));
    await tester.pumpAndSettle();

    // The server's key is not shown: it is translated, and with the same table
    // the stock by category uses.
    expect(find.text('Insumo médico'), findsWidgets);
    expect(find.text('MEDICAL_SUPPLY'), findsNothing);
  });

  testWidgets('the product search filters the local catalog', (tester) async {
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
    );

    await tester.tap(find.text('Añadir caja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir producto'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('product-search')), 'alcohol');
    await tester.pumpAndSettle();

    expect(find.text('Alcohol isopropílico'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsNothing);
  });
}
