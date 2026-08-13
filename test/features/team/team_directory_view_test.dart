import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/features/team/ui/team_directory_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Future<FakeHttpAdapter> pumpDirectory(
    WidgetTester tester, {
    required bool coordinator,
    String? centerId = 'center-1',
    List<Map<String, Object?>>? people,
    FakeResponse? inviteRefusal,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/reinvite')) {
        return FakeResponse(200, {'message': 'ok'});
      }
      if (options.method == 'POST') {
        return inviteRefusal ?? FakeResponse(201, userJson());
      }
      return FakeResponse(200, people ?? [userJson()]);
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
        myCenterIdProvider.overrideWithValue(centerId),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TeamDirectoryView()),
      ),
    );
    await tester.pumpAndSettle();
    return adapter;
  }

  testWidgets('the team reads with each person’s role', (tester) async {
    await pumpDirectory(
      tester,
      coordinator: false,
      people: [
        userJson(fullName: 'Ana Pérez'),
        userJson(
          id: 'user-2',
          username: 'beto',
          fullName: 'Beto Ruiz',
          centerRole: 'coordinator',
        ),
      ],
    );

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.textContaining('Voluntariado'), findsOneWidget);
    expect(find.textContaining('Coordinación'), findsOneWidget);
  });

  testWidgets('a volunteer reads the team but does not manage it', (
    tester,
  ) async {
    // El backend exige coordinación para sumar y reenviar, y sigue decidiendo;
    // esto solo evita ofrecer algo que responderá 403.
    await pumpDirectory(tester, coordinator: false);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Reenviar acceso'), findsNothing);
  });

  testWidgets('coordination can add somebody and resend an access', (
    tester,
  ) async {
    await pumpDirectory(tester, coordinator: true);

    expect(find.widgetWithText(FloatingActionButton, 'Sumar'), findsOneWidget);
    expect(find.byTooltip('Reenviar acceso'), findsOneWidget);
  });

  testWidgets('a disabled account is marked and cannot be resent', (
    tester,
  ) async {
    // El servidor rechaza reinvitar una cuenta desactivada, y reactivarla es
    // trabajo de escritorio.
    await pumpDirectory(
      tester,
      coordinator: true,
      people: [userJson(isActive: false)],
    );

    expect(find.textContaining('cuenta desactivada'), findsOneWidget);
    expect(find.byTooltip('Reenviar acceso'), findsNothing);
  });

  testWidgets('a session without a center says so instead of failing', (
    tester,
  ) async {
    await pumpDirectory(tester, coordinator: true, centerId: null);

    expect(find.textContaining('no pertenece a un centro'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('resending an access tells the person it went by email', (
    tester,
  ) async {
    final adapter = await pumpDirectory(tester, coordinator: true);

    await tester.tap(find.byTooltip('Reenviar acceso'));
    await tester.pumpAndSettle();

    expect(find.textContaining('acceso nuevo'), findsOneWidget);
    expect(
      adapter.requests.any((request) => request.path.endsWith('/reinvite')),
      isTrue,
    );
  });

  testWidgets('adding somebody sends what the server asked for', (
    tester,
  ) async {
    final adapter = await pumpDirectory(tester, coordinator: true);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Sumar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'beto@centro.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre de usuario'),
      'beto',
    );
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();

    final invite = adapter.requests.firstWhere((r) => r.method == 'POST');
    expect((invite.data! as Map)['email'], 'beto@centro.test');
    expect((invite.data! as Map)['center_role'], 'volunteer');
    expect(find.textContaining('Invitación enviada'), findsOneWidget);
  });

  testWidgets('an email already taken is said in Spanish', (tester) async {
    // El servidor contesta «Email already registered»; quien opera lee otra
    // cosa, y el rechazo sigue siendo el del servidor.
    await pumpDirectory(
      tester,
      coordinator: true,
      inviteRefusal: const FakeResponse(400, {
        'error': {'code': 'EMAIL_TAKEN', 'message': 'Email already registered'},
      }),
    );

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Sumar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo'),
      'ana@centro.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre de usuario'),
      'ana',
    );
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ya tiene una cuenta'), findsOneWidget);
  });

  testWidgets('an incomplete invitation does not leave the phone', (
    tester,
  ) async {
    final adapter = await pumpDirectory(tester, coordinator: true);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Sumar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar invitación'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el correo'), findsOneWidget);
    expect(adapter.requests.any((r) => r.method == 'POST'), isFalse);
  });
}
