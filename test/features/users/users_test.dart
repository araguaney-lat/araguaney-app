import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/studio_api.dart';
import 'package:araguaney_app/core/api/generated/models/studio_user_create.dart';
import 'package:araguaney_app/core/api/generated/models/user_out.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/centers/data/centers_providers.dart';
import 'package:araguaney_app/features/centers/data/centers_repository.dart';
import 'package:araguaney_app/features/users/data/users_repository.dart';
import 'package:araguaney_app/features/users/ui/user_record_view.dart';
import 'package:araguaney_app/features/users/ui/users_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Map<String, Object?> userJson({
    String id = 'user-1',
    String username = 'ana',
    String? fullName = 'Ana Pérez',
    String email = 'ana@araguaney.lat',
    String? centerRole = 'volunteer',
    String? centerId = 'center-1',
    bool isActive = true,
    bool totpEnabled = false,
  }) => {
    'id': id,
    'email': email,
    'username': username,
    'full_name': fullName,
    'avatar_url': null,
    'role': 'user',
    'center_role': centerRole,
    'center_id': centerId,
    'country_code': 'VE',
    'is_active': isActive,
    'totp_enabled': totpEnabled,
    'must_accept_terms': false,
  };

  group('asking the server', () {
    test('the filters it understands are the ones that travel', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, [userJson()]));

      await UsersRepository(
        StudioApi(fakeDio(adapter)),
      ).list(centerId: 'center-1', centerRole: 'coordinator', isActive: false);

      final query = adapter.requests.single.queryParameters;
      expect(adapter.requests.single.path, '/v1/studio/users');
      expect(query['center_id'], 'center-1');
      expect(query['center_role'], 'coordinator');
      expect(query['is_active'], false);
    });

    test('inviting carries no password, because it never has one', () async {
      // The server generates it and sends it by email; this client not touching
      // it is the only way it cannot leak it.
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, userJson()));

      await UsersRepository(StudioApi(fakeDio(adapter))).invite(
        const StudioUserCreate(
          email: 'nueva@araguaney.lat',
          username: 'nueva',
          centerRole: 'volunteer',
        ),
      );

      // The contract has the field; what matters is that this application never
      // fills it in, never asks for it and never shows it.
      final body = adapter.requests.single.data as Map<String, Object?>;
      expect(body['password'], isNull);
      expect(body['email'], 'nueva@araguaney.lat');
    });

    test('resending an access is refused with the server reason', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(400, {
          'error': {
            'code': 'ACCOUNT_DISABLED',
            'message': 'Cannot reinvite a disabled account',
          },
        }),
      );

      final outcome = await UsersRepository(
        StudioApi(fakeDio(adapter)),
      ).resendAccess('user-1');

      expect((outcome as UsersRefused<void>).failure.code, 'ACCOUNT_DISABLED');
    });
  });

  group('on screen', () {
    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      required FakeHttpAdapter adapter,
    }) async {
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          centersProvider.overrideWith(
            (ref) async =>
                CentersRead([centerOut(id: 'center-1', name: 'Caracas')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the text box says it only narrows what was loaded', (
      tester,
    ) async {
      // The server does not search by text. Calling it «search» would make
      // people believe an absent name does not exist, when it may be on another
      // page.
      await pump(
        tester,
        const UsersListView(),
        adapter: FakeHttpAdapter((_) => FakeResponse(200, [userJson()])),
      );

      expect(find.text('Filtrar lo cargado'), findsOneWidget);
      expect(
        find.textContaining('el texto recorta lo que ya se trajo'),
        findsOneWidget,
      );
    });

    testWidgets('narrowing to nothing says how many it looked at', (
      tester,
    ) async {
      await pump(
        tester,
        const UsersListView(),
        adapter: FakeHttpAdapter(
          (_) => FakeResponse(200, [userJson(), userJson(id: 'user-2')]),
        ),
      );

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('Ninguna de las 2 cargadas'), findsOneWidget);
    });

    testWidgets('a session that cannot manage people is told', (tester) async {
      await pump(
        tester,
        const UsersListView(),
        adapter: FakeHttpAdapter(
          (_) => FakeResponse(403, {
            'error': {'code': 'FORBIDDEN', 'message': 'User manager required'},
          }),
        ),
      );

      expect(
        find.text('Solo quien administra personas puede ver esta lista.'),
        findsOneWidget,
      );
    });

    testWidgets('a disabled account is not offered a resend', (tester) async {
      // The server refuses it, and activating the account is desk work.
      await pump(
        tester,
        UserRecordView(user: UserOut.fromJson(userJson(isActive: false))),
        adapter: FakeHttpAdapter((_) => const FakeResponse(200, [])),
      );

      expect(find.text('Reenviar el acceso'), findsNothing);
      expect(find.text('cuenta desactivada'), findsOneWidget);
    });

    testWidgets('the record says nobody here will ever see a password', (
      tester,
    ) async {
      await pump(
        tester,
        UserRecordView(user: UserOut.fromJson(userJson())),
        adapter: FakeHttpAdapter((_) => const FakeResponse(200, [])),
      );

      expect(find.text('Reenviar el acceso'), findsOneWidget);
      expect(
        find.textContaining('La contraseña la genera el servidor'),
        findsOneWidget,
      );
    });
  });
}
