import 'dart:convert';

import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/exports_api.dart';
import 'package:araguaney_app/core/api/generated/clients/shipments_api.dart';
import 'package:araguaney_app/core/api/generated/models/reception_exception_in.dart';
import 'package:araguaney_app/core/api/generated/models/reception_pallet_weight_in.dart';
import 'package:araguaney_app/core/api/generated/models/shipment_detail_out.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/shipments/data/shipments_repository.dart';
import 'package:araguaney_app/features/shipments/ui/register_reception_view.dart';
import 'package:araguaney_app/features/shipments/ui/shipment_record_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  ShipmentsRepository repositoryFor(FakeHttpAdapter adapter) =>
      ShipmentsRepository(
        shipments: ShipmentsApi(fakeDio(adapter)),
        exports: ExportsApi(fakeDio(adapter)),
      );

  Map<String, Object?> shipmentDetail({String status = 'DELIVERED'}) => {
    ...shipmentJson(status: status),
    'height_profile': null,
    'height_warnings': const <String>[],
    'delivered_at': null,
    'reconciled_at': null,
    'pallets': [
      {
        ...palletDetailJson(id: 'pallet-1', code: 'TM-0001'),
        'boxes': [
          boxJson(id: 'box-1', code: 'CJ-0001'),
          boxJson(id: 'box-2', code: 'CJ-0002'),
        ],
      },
    ],
  };

  group('writing a milestone', () {
    test('it carries what happened, and when if somebody said when', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, shipmentJson()));

      await repositoryFor(adapter).addMilestone(
        shipmentId: 'shipment-1',
        milestone: 'CUSTOMS_CLEARED',
        note: 'Salió de aduana',
        occurredAt: testNow,
      );

      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['milestone'], 'CUSTOMS_CLEARED');
      expect(body['note'], 'Salió de aduana');
      expect(body['occurred_at'], isNotNull);
      expect(
        adapter.requests.single.path,
        '/v1/shipments/shipment-1/milestones',
      );
    });

    test('with no date the server stamps it', () async {
      // The consignee's report arrives late and describes something from
      // yesterday; «now» is only the default case.
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, shipmentJson()));

      await repositoryFor(
        adapter,
      ).addMilestone(shipmentId: 'shipment-1', milestone: 'ARRIVED_AIRPORT');

      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['occurred_at'], isNull);
    });
  });

  group('registering the reception', () {
    test('only what did not arrive well travels', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(201, {
          'id': 'reception-1',
          'shipment_id': 'shipment-1',
          'received_at': testNow.toIso8601String(),
          'consignee_name': null,
          'notes': null,
          'lines': const <Object?>[],
          'pallet_weights': const <Object?>[],
          'shrinkage': {
            'total_boxes': 2,
            'received': 1,
            'not_received': 1,
            'shrinkage_pct': 50.0,
          },
        }),
      );

      await repositoryFor(adapter).registerReception(
        shipmentId: 'shipment-1',
        exceptions: const [
          ReceptionExceptionIn(
            boxId: 'box-2',
            outcome: ReceptionOutcome.missing,
          ),
        ],
        palletWeights: const [
          ReceptionPalletWeightIn(palletId: 'pallet-1', grossWeightKg: '120.5'),
        ],
        consigneeName: 'Cruz Roja',
      );

      // What really travels is compared, with the nested objects already
      // serialised.
      final body =
          jsonDecode(jsonEncode(adapter.requests.single.data))
              as Map<String, Object?>;
      expect(body['exceptions'], [
        {'box_id': 'box-2', 'outcome': 'MISSING', 'note': null},
      ]);
      expect(body['pallet_weights'], [
        {'pallet_id': 'pallet-1', 'gross_weight_kg': '120.5'},
      ]);
      expect(body['consignee_name'], 'Cruz Roja');
    });

    test('a second reception is refused with the server reason', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(409, {
          'error': {
            'code': 'ALREADY_RECONCILED',
            'message': 'This shipment already has a reception',
          },
        }),
      );

      final outcome = await repositoryFor(
        adapter,
      ).registerReception(shipmentId: 'shipment-1');

      expect((outcome as ShipmentRefused).failure.code, 'ALREADY_RECONCILED');
    });
  });

  group('the documents', () {
    test('each one is its own route behind the same gesture', () async {
      for (final document in ShipmentDocument.values) {
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(
            202,
            exportJobJson(status: 'DONE', downloadUrl: 'https://files.test/a'),
          ),
        );

        await repositoryFor(
          adapter,
        ).document('shipment-1', document, wait: (_) async {});

        expect(adapter.requests.first.method, 'POST');
        expect(
          adapter.requests.first.path,
          startsWith('/v1/shipments/shipment-1/'),
        );
      }
    });
  });

  group('on the record', () {
    Future<void> pumpRecord(
      WidgetTester tester, {
      required String status,
      bool national = true,
      Map<String, Object?>? reception,
    }) async {
      final adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('/reception')) {
          return reception == null
              ? const FakeResponse(404, {
                  'error': {'code': 'NOT_FOUND', 'message': 'no'},
                })
              : FakeResponse(200, reception);
        }
        if (options.path.endsWith('/events') ||
            options.path.endsWith('/incidents')) {
          return const FakeResponse(200, []);
        }
        return FakeResponse(200, shipmentDetail(status: status));
      });

      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          isCenterCoordinatorProvider.overrideWithValue(true),
          isNationalAdminProvider.overrideWithValue(national),
        ],
      );
      addTearDown(container.dispose);

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

    testWidgets('a dispatched shipment offers to be marked delivered', (
      tester,
    ) async {
      await pumpRecord(tester, status: 'SHIPPED');

      expect(find.text('Marcar como entregado'), findsOneWidget);
    });

    testWidgets('coordination is not offered to mark it delivered', (
      tester,
    ) async {
      // `require_national_admin`: the bar does not offer what answers 403.
      await pumpRecord(tester, status: 'SHIPPED', national: false);

      expect(find.text('Marcar como entregado'), findsNothing);
    });

    testWidgets('a delivered one offers to register what arrived', (
      tester,
    ) async {
      await pumpRecord(tester, status: 'DELIVERED');

      expect(find.text('Registrar la recepción'), findsOneWidget);
    });

    testWidgets('one already reconciled does not offer it twice', (
      tester,
    ) async {
      // It is recorded once only, so the step disappears instead of failing
      // with a 409.
      await pumpRecord(
        tester,
        status: 'RECONCILED',
        reception: {
          'id': 'reception-1',
          'shipment_id': 'shipment-1',
          'received_at': testNow.toIso8601String(),
          'consignee_name': null,
          'notes': null,
          'lines': const <Object?>[],
          'pallet_weights': const <Object?>[],
          'shrinkage': {
            'total_boxes': 2,
            'received': 2,
            'not_received': 0,
            'shrinkage_pct': 0.0,
          },
        },
      );

      expect(find.text('Registrar la recepción'), findsNothing);
    });

    testWidgets('writing a milestone is offered to the role that has it', (
      tester,
    ) async {
      await pumpRecord(tester, status: 'SHIPPED');
      expect(find.byTooltip('Anotar un hito'), findsOneWidget);

      await pumpRecord(tester, status: 'SHIPPED', national: false);
      expect(find.byTooltip('Anotar un hito'), findsNothing);
    });
  });

  group('the reception screen', () {
    testWidgets('it says the reception is written once, before writing it', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, shipmentDetail()),
      );
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegisterReceptionView(
              shipment: ShipmentDetailOut.fromJson(shipmentDetail()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CJ-0001'), findsOneWidget);
      expect(find.text('CJ-0002'), findsOneWidget);
      expect(
        find.textContaining('Marca solo las cajas que no llegaron bien'),
        findsOneWidget,
      );

      await tester.dragUntilVisible(
        find.byType(FilledButton),
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Se registra una sola vez'), findsOneWidget);
    });
  });
}
