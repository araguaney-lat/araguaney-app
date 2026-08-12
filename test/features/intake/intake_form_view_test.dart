import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/core/api/generated/clients/product_types_api.dart';
import 'package:araguaney_app/core/api/generated/models/box_draft.dart';
import 'package:araguaney_app/core/connectivity/connectivity_controller.dart';
import 'package:araguaney_app/core/db/app_database.dart';
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
        category: 'insumo',
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
    await probe.dispose();
  });

  Future<void> pumpForm(WidgetTester tester, FakeHttpAdapter adapter) async {
    final dio = fakeDio(adapter);
    final container = ProviderContainer(
      overrides: [
        captureIdGeneratorProvider.overrideWithValue(() => 'capture-fixed'),
        intakeRepositoryProvider.overrideWithValue(
          IntakeRepository(IntakesApi(dio)),
        ),
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(api: ProductTypesApi(dio), database: db),
        ),
        myCampaignsProvider.overrideWith((ref) async => []),
        // Estas pruebas son las de la fase anterior y siguen midiendo lo
        // mismo: con conexión la captura viaja en el momento. Sin sesión no
        // hay cola posible, que es exactamente lo que se quiere aquí.
        currentUserIdProvider.overrideWithValue(null),
        connectivityProbeProvider.overrideWithValue(probe),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IntakeFormView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Agrega una caja pasando por el selector de producto, como lo haría una
  /// persona.
  Future<void> addBox(
    WidgetTester tester, {
    String product = 'Paracetamol 500 mg',
  }) async {
    await tester.tap(find.text('Agregar caja'));
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

    final send = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Enviar'),
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
    final send = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Enviar'),
    );
    expect(send.onPressed, isNotNull);
    // El catálogo se buscó en el cache: la única petición posible sería la de
    // enviar, que todavía no ocurrió.
    expect(adapter.requests, isEmpty);
  });

  testWidgets('sending carries the boxes and the capture id', (tester) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
    await pumpForm(tester, adapter);
    await addBox(tester);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    final body = adapter.requests.single.data as Map<String, dynamic>;
    expect(body['capture_id'], 'capture-fixed');
    // Retrofit deja los objetos anidados sin serializar hasta que dio los
    // codifica; leerlos tipados es más fiel que asumir un mapa.
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

    await tester.tap(find.text('Enviar'));
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

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    // El servidor pregunta; la persona registra el motivo en vez de detenerse.
    expect(find.text('Falta identificar a quien dona'), findsOneWidget);
    await tester.tap(find.text('No quiso identificarse'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Se fue sin dar datos');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar sin donante'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    final retry = adapter.requests.last.data as Map<String, dynamic>;
    // La misma llave de captura: reintentar no puede duplicar inventario.
    expect(retry['capture_id'], 'capture-fixed');
    expect(retry['anonymous_exception_reason'], 'Se fue sin dar datos');
    expect(find.text('Captura registrada'), findsOneWidget);
  });

  testWidgets('the product search filters the local catalog', (tester) async {
    await pumpForm(
      tester,
      FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
    );

    await tester.tap(find.text('Agregar caja'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir producto'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('product-search')), 'alcohol');
    await tester.pumpAndSettle();

    expect(find.text('Alcohol isopropílico'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsNothing);
  });
}
