import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/features/incidents/data/incidents_providers.dart';
import 'package:araguaney_app/features/incidents/ui/incidents_list_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';

Map<String, Object?> incidentJson({
  String id = 'i-1',
  String type = 'MISSING_BOX',
  String description = 'Falta una caja del segundo pallet',
  String status = 'OPEN',
  String? resolutionNote,
  String createdAt = '2026-08-01T00:00:00Z',
}) => {
  'id': id,
  'shipment_id': 's-1',
  'pallet_id': null,
  'box_id': null,
  'type': type,
  'description': description,
  'status': status,
  'resolution_note': resolutionNote,
  'resolved_at': status == 'OPEN' ? null : '2026-08-05T00:00:00Z',
  'created_at': createdAt,
};

void main() {
  late List<RequestOptions> sent;

  setUp(() => sent = []);

  Future<void> pumpList(
    WidgetTester tester, {
    List<Map<String, Object?>> incidents = const [],
    bool canResolve = true,
    FakeResponse? listResponse,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      sent.add(options);
      if (options.method == 'POST') {
        return FakeResponse(200, incidentJson(status: 'RESOLVED'));
      }
      return listResponse ?? FakeResponse(200, incidents);
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        canResolveIncidentsProvider.overrideWithValue(canResolve),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: IncidentsListView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('what was reported can finally be seen', (tester) async {
    // La aplicación sabía levantar una incidencia y no sabía enseñarla, que es
    // la peor mitad para que falte.
    await pumpList(tester, incidents: [incidentJson()]);

    expect(find.text('Caja faltante'), findsOneWidget);
    expect(find.text('«Falta una caja del segundo pallet»'), findsOneWidget);
    expect(find.text('Abierta'), findsOneWidget);
  });

  testWidgets('open ones come first, oldest at the top', (tester) async {
    // Una incidencia vieja y abierta es exactamente la que se está olvidando.
    await pumpList(
      tester,
      incidents: [
        incidentJson(
          id: 'i-new',
          description: 'reciente',
          createdAt: '2026-08-20T00:00:00Z',
        ),
        incidentJson(
          id: 'i-done',
          description: 'cerrada',
          status: 'RESOLVED',
          resolutionNote: 'Apareció',
          createdAt: '2026-08-02T00:00:00Z',
        ),
        incidentJson(
          id: 'i-old',
          description: 'vieja',
          createdAt: '2026-08-01T00:00:00Z',
        ),
      ],
    );

    final quoted = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => s.startsWith('«'))
        .toList();
    expect(quoted, ['«vieja»', '«reciente»', '«cerrada»']);
    expect(find.text('2 incidencias abiertas'), findsOneWidget);
  });

  testWidgets('a closed one shows how it ended', (tester) async {
    // Es lo unico que le queda a quien la reporto.
    await pumpList(
      tester,
      incidents: [
        incidentJson(status: 'RESOLVED', resolutionNote: 'Apareció en aduana'),
      ],
    );

    expect(find.text('Cerrada: Apareció en aduana'), findsOneWidget);
  });

  testWidgets('without the role there is no way to close one', (tester) async {
    // Cerrar exige administración nacional; listar, solo coordinación.
    await pumpList(tester, incidents: [incidentJson()], canResolve: false);

    expect(find.text('Caja faltante'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Cerrar'), findsNothing);
  });

  /// Con la hoja abierta hay dos «Cerrar»: el de la tarjeta, debajo, y el de
  /// la hoja. En pantalla solo se ve uno; aquí hay que decir cuál.
  Finder sheetButton(String label) => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.widgetWithText(FilledButton, label),
  );

  testWidgets('closing without a note does not leave', (tester) async {
    await pumpList(tester, incidents: [incidentJson()]);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(sheetButton('Cerrar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe en qué terminó'), findsOneWidget);
    expect(sent.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('the note travels as it was written', (tester) async {
    await pumpList(tester, incidents: [incidentJson()]);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Apareció en el andén');
    await tester.tap(sheetButton('Cerrar'));
    await tester.pumpAndSettle();

    final post = sent.firstWhere((r) => r.method == 'POST');
    expect(post.path, contains('/resolve'));
    expect((post.data! as Map)['note'], 'Apareció en el andén');
  });

  testWidgets('the sheet shows what was reported while closing it', (
    tester,
  ) async {
    // Cerrar sin releerlo es como se cierra la equivocada.
    await pumpList(tester, incidents: [incidentJson()]);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('«Falta una caja del segundo pallet»'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('nothing reported says so', (tester) async {
    await pumpList(tester);

    expect(find.text('No hay incidencias registradas.'), findsOneWidget);
  });

  testWidgets('a refusal is read as an answer', (tester) async {
    await pumpList(
      tester,
      listResponse: FakeResponse(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'Coordinator required'},
      }),
    );

    expect(find.textContaining('Hace falta coordinar'), findsOneWidget);
  });
}
