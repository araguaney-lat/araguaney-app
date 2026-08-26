import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/platform/open_link.dart';
import 'package:araguaney_app/features/shipments/ui/shipment_record_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

late FakeHttpAdapter _adapter;

void main() {
  Future<void> pumpRecord(
    WidgetTester tester, {
    required bool coordinator,
    bool national = false,
    Map<String, Object?>? reception,
    List<Map<String, Object?>>? incidents,
    List<Map<String, Object?>>? events,
    Map<String, Object?>? manifestJob,
    List<String>? opened,
    List<LinkTarget>? targets,
    int receptionStatus = 200,
    String status = 'DELIVERED',
    List<Map<String, Object?>> pallets = const [],
    List<String> heightWarnings = const [],
  }) async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/events')) {
        return FakeResponse(200, events ?? const []);
      }
      if (options.path.endsWith('/manifest.pdf')) {
        return FakeResponse(
          202,
          manifestJob ??
              exportJobJson(
                status: 'DONE',
                downloadUrl: 'https://files.test/manifiesto.pdf',
              ),
        );
      }
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
      return FakeResponse(
        200,
        shipmentJson(
          reference: 'ENV-77',
          status: status,
          pallets: pallets,
          heightWarnings: heightWarnings,
        ),
      );
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
        // The record also asks about national administration: delivering and
        // recording the reception belong to it.
        isNationalAdminProvider.overrideWithValue(national),
        openLinkProvider.overrideWithValue((
          url, {
          target = LinkTarget.systemApp,
        }) async {
          opened?.add(url);
          targets?.add(target);
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    _adapter = adapter;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

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

    // The incidents go at the end of the record: on a phone you have to scroll.
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
    // The backend requires coordination to raise them and goes on deciding;
    // this only avoids offering something that will answer 403.
    await pumpRecord(tester, coordinator: false);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('ENV-77'), findsOneWidget);
  });

  testWidgets('the journey reads milestones and state changes together', (
    tester,
  ) async {
    await pumpRecord(
      tester,
      coordinator: true,
      events: [
        qrEventJson(fromStatus: 'CLOSED', toStatus: 'SHIPPED'),
        qrEventJson(
          fromStatus: 'SHIPPED',
          toStatus: 'SHIPPED',
          milestone: 'CUSTOMS_CLEARED',
          note: 'Sin inspección',
        ),
      ],
    );

    await tester.scrollUntilVisible(find.text('Liberado de aduana'), 200);

    expect(find.text('Cerrado → Despachado'), findsOneWidget);
    expect(find.textContaining('Sin inspección'), findsOneWidget);
  });

  testWidgets('a shipment without events says so instead of showing nothing', (
    tester,
  ) async {
    await pumpRecord(tester, coordinator: true, events: const []);

    await tester.scrollUntilVisible(
      find.textContaining('Todavía no hay hitos'),
      200,
    );

    expect(find.textContaining('Todavía no hay hitos'), findsOneWidget);
  });

  testWidgets('asking for the manifest opens it outside the application', (
    tester,
  ) async {
    // Outside and not inside: the manifest is a signed PDF, and the system's
    // viewer is where it gets saved, printed or sent. Bringing it into the
    // internal browser would take all of that away from whoever opens it.
    final opened = <String>[];
    final targets = <LinkTarget>[];

    await pumpRecord(
      tester,
      coordinator: true,
      opened: opened,
      targets: targets,
    );
    // There are now four documents behind the same icon, so one gets chosen.
    await tester.tap(find.byTooltip('Documentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manifiesto (PDF)'));
    await tester.pumpAndSettle();

    expect(opened, ['https://files.test/manifiesto.pdf']);
    expect(targets, [LinkTarget.systemApp]);
  });

  testWidgets('a manifest the server could not build says why', (tester) async {
    await pumpRecord(
      tester,
      coordinator: true,
      manifestJob: exportJobJson(
        status: 'FAILED',
        error: 'El envío no tiene tarimas',
      ),
      opened: <String>[],
    );
    await tester.tap(find.byTooltip('Documentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manifiesto (PDF)'));
    await tester.pumpAndSettle();

    expect(find.text('El envío no tiene tarimas'), findsOneWidget);
  });

  group('advancing the shipment', () {
    testWidgets('an open one offers to close, naming what it carries', (
      tester,
    ) async {
      await pumpRecord(
        tester,
        coordinator: true,
        status: 'OPEN',
        pallets: [palletDetailJson(code: 'TM-0001')],
      );

      expect(find.text('Abierto'), findsOneWidget);
      await tester.tap(find.text('Cerrar el envío'));
      await tester.pumpAndSettle();

      // Closing is not undone, so it says what is at stake beforehand.
      expect(find.text('¿Cerrar el envío?'), findsOneWidget);
      expect(find.textContaining('1 tarima'), findsOneWidget);
      expect(find.textContaining('Caracas'), findsWidgets);
    });

    testWidgets('saying «todavía no» changes nothing', (tester) async {
      await pumpRecord(tester, coordinator: true, status: 'OPEN');

      await tester.tap(find.text('Cerrar el envío'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todavía no'));
      await tester.pumpAndSettle();

      expect(
        _adapter.requests.where((r) => r.path.endsWith('/close')),
        isEmpty,
      );
    });

    testWidgets('a closed one offers to dispatch, not to close again', (
      tester,
    ) async {
      await pumpRecord(tester, coordinator: true, status: 'CLOSED');

      expect(find.text('Despachar'), findsOneWidget);
      expect(find.text('Cerrar el envío'), findsNothing);
    });

    testWidgets('a dispatched one offers nothing further', (tester) async {
      // What comes next — delivering, reconciling — does not belong to the
      // origin centre.
      await pumpRecord(tester, coordinator: true, status: 'SHIPPED');

      expect(find.text('Despachar'), findsNothing);
      expect(find.text('Cerrar el envío'), findsNothing);
    });

    testWidgets('volunteering is offered nothing at all', (tester) async {
      await pumpRecord(tester, coordinator: false, status: 'OPEN');

      expect(find.text('Cerrar el envío'), findsNothing);
    });
  });

  group('the pallets it carries', () {
    testWidgets('an open shipment offers to add and to remove', (tester) async {
      await pumpRecord(
        tester,
        coordinator: true,
        status: 'OPEN',
        pallets: [palletDetailJson(code: 'TM-0001')],
      );

      expect(find.text('TM-0001'), findsOneWidget);
      expect(find.text('Añadir tarima'), findsOneWidget);
      expect(find.byTooltip('Quitar del envío'), findsOneWidget);
    });

    testWidgets('a closed one offers neither: it admits no changes', (
      tester,
    ) async {
      await pumpRecord(
        tester,
        coordinator: true,
        status: 'CLOSED',
        pallets: [palletDetailJson(code: 'TM-0001')],
      );

      expect(find.text('TM-0001'), findsOneWidget);
      expect(find.text('Añadir tarima'), findsNothing);
      expect(find.byTooltip('Quitar del envío'), findsNothing);
    });

    testWidgets('an empty one says so rather than showing a gap', (
      tester,
    ) async {
      await pumpRecord(tester, coordinator: true, status: 'OPEN');

      expect(
        find.textContaining('todavía no lleva ninguna tarima'),
        findsOneWidget,
      );
    });
  });

  testWidgets('a height warning is repeated as the server phrased it', (
    tester,
  ) async {
    // The threshold belongs to the shipment's profile and the server decides;
    // the application neither interprets it nor turns it into a block, because
    // the server does not either.
    await pumpRecord(
      tester,
      coordinator: true,
      status: 'OPEN',
      heightWarnings: ['TM-0001 supera la altura del perfil'],
    );

    expect(find.text('TM-0001 supera la altura del perfil'), findsOneWidget);
  });
}
