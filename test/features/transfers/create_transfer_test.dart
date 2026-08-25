import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/exports_api.dart';
import 'package:araguaney_app/core/api/generated/clients/transfers_api.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/centers/data/centers_providers.dart';
import 'package:araguaney_app/features/centers/data/centers_repository.dart';
import 'package:araguaney_app/features/transfers/data/transfers_repository.dart';
import 'package:araguaney_app/features/transfers/ui/create_transfer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  TransfersRepository repositoryFor(FakeHttpAdapter adapter) =>
      TransfersRepository(
        transfers: TransfersApi(fakeDio(adapter)),
        exports: ExportsApi(fakeDio(adapter)),
      );

  Map<String, Object?> transferJson() => {
    'id': 'transfer-1',
    'from_center_id': 'center-1',
    'to_center_id': 'center-2',
    'status': 'REQUESTED',
    'initiated_by': 'user-1',
    'notes': null,
    'created_at': testNow.toIso8601String(),
    'updated_at': testNow.toIso8601String(),
  };

  group('proposing one', () {
    test('it carries the boxes, not an amount of anything', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, transferJson()));

      await repositoryFor(adapter).create(
        fromCenterId: 'center-1',
        toCenterId: 'center-2',
        boxIds: const ['box-1', 'box-2'],
        notes: 'Les falta suero',
      );

      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['box_ids'], ['box-1', 'box-2']);
      expect(body['from_center_id'], 'center-1');
      expect(body['to_center_id'], 'center-2');
      expect(body['notes'], 'Les falta suero');
    });

    test('a refusal keeps the words the server chose', () async {
      // One bad box refuses the whole list, and its reason is the server's:
      // that it is not sealed, that it already travels somewhere else.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(400, {
          'error': {
            'code': 'BOX_NOT_SEALED',
            'message': 'Box box-2 must be SEALED to transfer',
          },
        }),
      );

      final outcome = await repositoryFor(adapter).create(
        fromCenterId: 'center-1',
        toCenterId: 'center-2',
        boxIds: const ['box-2'],
      );

      expect(
        (outcome as TransferRefused).failure.message,
        'Box box-2 must be SEALED to transfer',
      );
    });
  });

  group('the screen', () {
    Future<void> pumpCreate(
      WidgetTester tester, {
      required FakeHttpAdapter adapter,
    }) async {
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          appDatabaseProvider.overrideWithValue(db),
          myCenterIdProvider.overrideWithValue('center-1'),
          isNationalAdminProvider.overrideWithValue(false),
          centersProvider.overrideWith(
            (ref) async => CentersRead([
              centerOut(id: 'center-1', name: 'Caracas'),
              centerOut(id: 'center-2', name: 'Valencia'),
            ]),
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
            home: CreateTransferView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('this centre is not offered as a destination', (tester) async {
      await pumpCreate(tester, adapter: OfflineHttpAdapter());
      await tester.tap(find.text('Centro de destino'));
      await tester.pumpAndSettle();

      expect(find.text('Valencia'), findsWidgets);
      // The server refuses origin == destination, and offering it would be
      // offering a refusal.
      expect(find.text('Caracas'), findsNothing);
    });

    testWidgets('nothing can be proposed with no boxes chosen', (tester) async {
      await pumpCreate(tester, adapter: OfflineHttpAdapter());

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Proponer la transferencia'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}
