import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/account/ui/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  Map<String, Object?> profileJson() => {
    'id': 'u-1',
    'username': 'quien',
    'email': 'quien@sea.example',
    'full_name': 'Quien Sea',
    'center_id': 'c-1',
    'center_name': 'Centro Caracas',
    'center_role': 'coordinator',
    'avatar_url': null,
    'campaigns': <Object?>[],
  };

  Map<String, Object?> meJson({required bool totp, bool terms = false}) => {
    'id': 'u-1',
    'username': 'quien',
    'email': 'quien@sea.example',
    'full_name': 'Quien Sea',
    'role': 'user',
    'is_active': true,
    'must_accept_terms': terms,
    'totp_enabled': totp,
    'avatar_url': null,
    'center_id': 'c-1',
    'center_role': 'coordinator',
    'country_code': null,
  };

  Future<void> pumpProfile(
    WidgetTester tester, {
    required bool totp,
    bool terms = false,
  }) async {
    final dio = fakeDio(
      FakeHttpAdapter(
        (options) => FakeResponse(
          200,
          options.path.endsWith('/profile')
              ? profileJson()
              : meJson(totp: totp, terms: terms),
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [restClientProvider.overrideWithValue(RestClient(dio))],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProfileView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('it says who you are, with the centre named', (tester) async {
    await pumpProfile(tester, totp: false);

    expect(find.text('Quien Sea'), findsOneWidget);
    expect(find.text('quien@sea.example'), findsOneWidget);
    expect(find.text('Centro Caracas'), findsOneWidget);
    // El rol se lee en español, no como la clave del servidor.
    expect(find.text('Coordinación'), findsOneWidget);
    expect(find.text('coordinator'), findsNothing);
  });

  testWidgets('with no second factor it says what that means', (tester) async {
    // No es un ajuste apagado: es una cuenta protegida solo por su contraseña,
    // y decirlo así es la diferencia entre un interruptor y una advertencia.
    await pumpProfile(tester, totp: false);

    expect(
      find.textContaining('tu contraseña es lo único que protege'),
      findsOneWidget,
    );
  });

  testWidgets('with the second factor on it says so', (tester) async {
    await pumpProfile(tester, totp: true);

    expect(find.textContaining('Activada'), findsOneWidget);
  });

  testWidgets('changing the password is offered before it is demanded', (
    tester,
  ) async {
    await pumpProfile(tester, totp: false);

    expect(find.textContaining('no solo cuando toca'), findsOneWidget);
  });

  testWidgets('pending terms are offered, never interposed', (tester) async {
    // El servidor no bloquea por ellos, así que la aplicación tampoco.
    await pumpProfile(tester, totp: false, terms: true);

    expect(find.text('Términos pendientes de aceptar'), findsOneWidget);
  });

  testWidgets('with terms already accepted nothing is said about them', (
    tester,
  ) async {
    await pumpProfile(tester, totp: false);

    expect(find.text('Términos pendientes de aceptar'), findsNothing);
  });
}
