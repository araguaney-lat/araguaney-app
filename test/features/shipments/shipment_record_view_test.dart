import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/features/shipments/ui/shipment_record_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Future<void> pumpRecord(
    WidgetTester tester, {
    required bool coordinator,
    Map<String, Object?>? reception,
    List<Map<String, Object?>>? incidents,
    int receptionStatus = 200,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/reception')) {
        return FakeResponse(
          receptionStatus,
          receptionStatus == 200
              ? (reception ?? receptionJson())
              : {
                  'error': {'code': 'NOT_FOUND', 'message': 'no existe'},
                },
        );
      }
      if (options.path.endsWith('/incidents')) {
        return FakeResponse(200, incidents ?? const []);
      }
      return FakeResponse(200, shipmentJson(reference: 'ENV-77'));
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ShipmentRecordView(shipmentId: 'shipment-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a reconciled shipment shows what arrived and what did not', (
    tester,
  ) async {
    await pumpRecord(
      tester,
      coordinator: true,
      reception: receptionJson(received: 8, totalBoxes: 10),
      incidents: [incidentJson(description: 'Dos cajas mojadas')],
    );

    expect(find.text('ENV-77'), findsOneWidget);
    expect(find.text('8 de 10 llegaron bien'), findsOneWidget);

    // Las incidencias van al final de la ficha: en un teléfono hay que bajar.
    await tester.scrollUntilVisible(find.text('Daño'), 200);

    expect(find.text('Daño'), findsOneWidget);
    expect(find.text('Dos cajas mojadas'), findsOneWidget);
  });

  testWidgets('a shipment not reconciled says so instead of failing', (
    tester,
  ) async {
    await pumpRecord(tester, coordinator: true, receptionStatus: 404);

    expect(
      find.textContaining('Todavía no se registró la recepción'),
      findsOneWidget,
    );
    expect(find.textContaining('Ninguna incidencia'), findsOneWidget);
  });

  testWidgets('coordination can raise an incident', (tester) async {
    await pumpRecord(tester, coordinator: true);

    expect(
      find.widgetWithText(FloatingActionButton, 'Incidencia'),
      findsOneWidget,
    );
  });

  testWidgets('a volunteer reads but does not raise', (tester) async {
    // El backend exige coordinación para levantarlas y sigue decidiendo; esto
    // solo evita ofrecer algo que responderá 403.
    await pumpRecord(tester, coordinator: false);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('ENV-77'), findsOneWidget);
  });
}
