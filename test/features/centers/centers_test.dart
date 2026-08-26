import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/models/center_out.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/centers/data/centers_providers.dart';
import 'package:araguaney_app/features/centers/ui/center_form_view.dart';
import 'package:araguaney_app/features/centers/ui/centers_list_view.dart';
import 'package:araguaney_app/features/transfers/ui/transfers_list_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';

Map<String, Object?> centerJson({
  required String id,
  required String name,
  String? state = 'Miranda',
  String? country = 'VE',
  bool active = true,
}) => {
  'id': id,
  'name': name,
  'address': 'Calle 1',
  'contact_name': 'Rosa',
  'contact_email': 'rosa@ejemplo.test',
  'contact_phone': '+58 000',
  'country_code': country,
  'state_name': state,
  'is_active': active,
  'created_at': '2026-08-01T00:00:00Z',
};

Map<String, Object?> transferJson({
  required String id,
  required String from,
  required String to,
}) => {
  'id': id,
  'from_center_id': from,
  'to_center_id': to,
  'status': 'REQUESTED',
  'initiated_by': 'u-1',
  'created_at': '2026-08-02T00:00:00Z',
  'updated_at': '2026-08-02T00:00:00Z',
};

void main() {
  Future<void> pumpCenters(
    WidgetTester tester, {
    required FakeResponse Function(String path) respond,
    bool canList = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        canListCentersProvider.overrideWithValue(canList),
        restClientProvider.overrideWithValue(
          RestClient(
            fakeDio(FakeHttpAdapter((options) => respond(options.path))),
          ),
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
          home: CentersListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the centres list', () {
    testWidgets('a refusal is not an error, it is an answer', (tester) async {
      // Listing centres requires national administration, so a coordination
      // session gets a 403 every time. That is not a failure to report.
      await pumpCenters(
        tester,
        respond: (_) => FakeResponse(403, {
          'error': {'code': 'FORBIDDEN', 'message': 'National admin required'},
        }),
      );

      expect(
        find.textContaining('Solo la administración nacional'),
        findsOneWidget,
      );
    });

    testWidgets('deactivated centres go last and say so', (tester) async {
      // They still exist and are almost never what somebody comes looking for.
      await pumpCenters(
        tester,
        respond: (_) => FakeResponse(200, [
          centerJson(id: 'c-1', name: 'Zulia', active: false),
          centerJson(id: 'c-2', name: 'Anzoátegui'),
        ]),
      );

      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(titles, ['Anzoátegui', 'Zulia']);
      expect(find.text('Desactivado'), findsOneWidget);
    });

    testWidgets('a centre with no place shown has no second line', (
      tester,
    ) async {
      // The generated model brings these fields nullable: what does not arrive
      // is omitted instead of drawing an empty line.
      await pumpCenters(
        tester,
        respond: (_) => FakeResponse(200, [
          centerJson(id: 'c-1', name: 'Sin sitio', state: null, country: null),
        ]),
      );

      expect(tester.widget<ListTile>(find.byType(ListTile)).subtitle, isNull);
    });
  });

  group('naming the other centre in a transfer', () {
    Future<void> pumpTransfers(
      WidgetTester tester, {
      required bool canListCentres,
    }) async {
      final adapter = FakeHttpAdapter((options) {
        if (options.path.contains('/centers')) {
          return canListCentres
              ? FakeResponse(200, [centerJson(id: 'c-2', name: 'Anzoátegui')])
              : FakeResponse(403, {
                  'error': {'code': 'FORBIDDEN', 'message': 'nope'},
                });
        }
        return FakeResponse(200, [
          transferJson(id: 't-1', from: 'c-1', to: 'c-2'),
        ]);
      });

      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          myCenterIdProvider.overrideWithValue('c-1'),
          isNationalAdminProvider.overrideWithValue(canListCentres),
          // The list offers proposing a transfer, and that asks for the role:
          // without this the screen drags the whole session into the test.
          isCenterCoordinatorProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TransfersListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a session that can resolve it names the centre', (
      tester,
    ) async {
      await pumpTransfers(tester, canListCentres: true);

      expect(find.textContaining('Anzoátegui'), findsOneWidget);
    });

    testWidgets('a session that cannot stays silent, without a gap', (
      tester,
    ) async {
      // Showing an identifier would be worse than showing nothing. The row
      // stays as it was before this feature existed.
      await pumpTransfers(tester, canListCentres: false);

      expect(find.text('Saliente'), findsOneWidget);
      expect(find.textContaining('c-2'), findsNothing);
      // The second line is only the date: no name and no separator left
      // dangling.
      final row = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Saliente'),
          matching: find.byType(ListTile),
        ),
      );
      expect((row.subtitle! as Text).data, isNot(contains('·')));
    });
  });

  group('the centre form', () {
    Future<List<RequestOptions>> pumpForm(
      WidgetTester tester, {
      Map<String, Object?>? existing,
      FakeResponse? saveResponse,
    }) async {
      // Nine fields and a button do not fit in the harness's default window,
      // and scrolling in every test adds noise to what is being tested.
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final sent = <RequestOptions>[];
      final adapter = FakeHttpAdapter((options) {
        sent.add(options);
        if (options.method == 'GET') return FakeResponse(200, <Object?>[]);
        return saveResponse ??
            FakeResponse(200, centerJson(id: 'c-9', name: 'Nuevo'));
      });

      final container = ProviderContainer(
        overrides: [
          canListCentersProvider.overrideWithValue(true),
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

            home: CenterFormView(
              existing: existing == null ? null : CenterOut.fromJson(existing),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return sent;
    }

    Future<void> tapSave(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'only the name is required, because that is all the server asks',
      (tester) async {
        // Inventing required fields the contract does not have would be a
        // business rule of our own, which is exactly what this client does not
        // carry.
        final sent = await pumpForm(tester);

        await tester.tap(find.text('Crear centro'));
        await tester.pumpAndSettle();

        expect(find.text('Escribe nombre'), findsOneWidget);
        expect(sent.where((r) => r.method == 'POST'), isEmpty);
      },
    );

    testWidgets('a name alone is enough to create one', (tester) async {
      final sent = await pumpForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Centro Nuevo');
      await tapSave(tester, 'Crear centro');

      final post = sent.firstWhere((r) => r.method == 'POST');
      final body = post.data! as Map;
      expect(body['name'], 'Centro Nuevo');
      // What is empty does not travel as an empty string: it travels absent.
      expect(body['address'], isNull);
      expect(body['legal_name'], isNull);
    });

    testWidgets('editing arrives filled in', (tester) async {
      await pumpForm(
        tester,
        existing: centerJson(id: 'c-1', name: 'Zulia'),
      );

      expect(find.text('Editar centro'), findsOneWidget);
      expect(find.text('Zulia'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('a refusal is shown as the server phrased it', (tester) async {
      // It describes something whoever writes can correct, like a malformed
      // email address, and that is why it reaches the screen whole.
      await pumpForm(
        tester,
        saveResponse: FakeResponse(422, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'El correo del contacto no es válido',
          },
        }),
      );

      await tester.enterText(find.byType(TextFormField).first, 'Centro Nuevo');
      await tapSave(tester, 'Crear centro');

      expect(find.text('El correo del contacto no es válido'), findsOneWidget);
    });
  });
}
