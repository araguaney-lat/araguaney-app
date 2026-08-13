import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/models/campaign_out.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/team/ui/campaign_members_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Future<FakeHttpAdapter> pumpMembers(
    WidgetTester tester, {
    required bool coordinator,
    List<CampaignOut>? campaigns,
    List<Map<String, Object?>>? members,
    List<Map<String, Object?>>? centerPeople,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      if (options.method == 'DELETE') return const FakeResponse(204, null);
      if (options.method == 'POST') return FakeResponse(201, {'ok': true});
      if (options.path.contains('/members')) {
        return FakeResponse(200, members ?? [campaignMemberJson()]);
      }
      return FakeResponse(200, centerPeople ?? [userJson()]);
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        isCenterCoordinatorProvider.overrideWithValue(coordinator),
        myCenterIdProvider.overrideWithValue('center-1'),
        myCampaignsProvider.overrideWith(
          (ref) async => campaigns ?? [campaign()],
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CampaignMembersView()),
      ),
    );
    await tester.pumpAndSettle();
    return adapter;
  }

  /// Elegir una campaña en el desplegable: la pantalla no elige por su cuenta.
  Future<void> chooseCampaign(WidgetTester tester, String name) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing is listed until a campaign is chosen', (tester) async {
    await pumpMembers(tester, coordinator: true);

    expect(find.textContaining('Elige una campaña'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('a chosen campaign lists who takes part in it', (tester) async {
    await pumpMembers(
      tester,
      coordinator: true,
      members: [
        campaignMemberJson(fullName: 'Ana Pérez'),
        campaignMemberJson(
          id: 'user-2',
          username: 'beto',
          fullName: 'Beto Ruiz',
          centerRole: 'coordinator',
        ),
      ],
    );
    await chooseCampaign(tester, 'Campaña de invierno');

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Beto Ruiz'), findsOneWidget);
  });

  testWidgets('a volunteer reads the members but does not move them', (
    tester,
  ) async {
    await pumpMembers(tester, coordinator: false);
    await chooseCampaign(tester, 'Campaña de invierno');

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Sacar de la campaña'), findsNothing);
  });

  testWidgets('nobody is taken out of the general campaign', (tester) async {
    // El servidor responde 422 si se intenta; ofrecerlo sería prometer algo
    // que no se puede cumplir.
    await pumpMembers(
      tester,
      coordinator: true,
      campaigns: [campaign(name: 'General', isGeneral: true)],
    );
    await chooseCampaign(tester, 'General');

    expect(find.byTooltip('Sacar de la campaña'), findsNothing);
    expect(find.textContaining('campaña general'), findsOneWidget);
  });

  testWidgets('taking somebody out asks first', (tester) async {
    final adapter = await pumpMembers(tester, coordinator: true);
    await chooseCampaign(tester, 'Campaña de invierno');

    await tester.tap(find.byTooltip('Sacar de la campaña'));
    await tester.pumpAndSettle();
    expect(find.textContaining('dejará de participar'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(adapter.requests.any((r) => r.method == 'DELETE'), isFalse);
  });

  testWidgets('confirming takes the person out', (tester) async {
    final adapter = await pumpMembers(tester, coordinator: true);
    await chooseCampaign(tester, 'Campaña de invierno');

    await tester.tap(find.byTooltip('Sacar de la campaña'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sacar'));
    await tester.pumpAndSettle();

    expect(adapter.requests.any((r) => r.method == 'DELETE'), isTrue);
  });

  testWidgets('adding does not offer somebody who is already in', (
    tester,
  ) async {
    await pumpMembers(
      tester,
      coordinator: true,
      members: [campaignMemberJson(fullName: 'Ana Pérez')],
      centerPeople: [
        userJson(fullName: 'Ana Pérez'),
        userJson(id: 'user-2', username: 'beto', fullName: 'Beto Ruiz'),
      ],
    );
    await chooseCampaign(tester, 'Campaña de invierno');

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Sumar'));
    await tester.pumpAndSettle();

    expect(find.text('Beto Ruiz'), findsOneWidget);
    // Ana ya participa: sigue en la lista de atrás, pero no en la hoja.
    expect(find.text('Ana Pérez'), findsOneWidget);
  });
}
