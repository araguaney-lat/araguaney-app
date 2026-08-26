import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/campaigns_api.dart';
import 'package:araguaney_app/core/api/generated/models/campaign_create.dart';
import 'package:araguaney_app/core/api/generated/models/campaign_out.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/campaigns/data/campaigns_providers.dart';
import 'package:araguaney_app/features/campaigns/data/campaigns_repository.dart';
import 'package:araguaney_app/features/campaigns/ui/campaign_record_view.dart';
import 'package:araguaney_app/features/campaigns/ui/campaigns_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Map<String, Object?> campaignJson({
    String id = 'campaign-1',
    String name = 'Emergencia',
    bool isGeneral = false,
    bool isActive = true,
  }) => {
    'id': id,
    'name': name,
    'slug': null,
    'description': 'Para el estado Vargas',
    'is_active': isActive,
    'is_general': isGeneral,
    'start_date': null,
    'end_date': null,
    'origin_country': null,
    'destination_country': null,
    'weight_goal_kg': null,
    'created_at': testNow.toIso8601String(),
  };

  group('asking the server', () {
    test('the list asks only for the ones still running', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [campaignJson()]),
      );

      await CampaignsRepository(CampaignsApi(fakeDio(adapter))).list();

      expect(adapter.requests.single.path, '/v1/campaigns');
      expect(adapter.requests.single.queryParameters['active_only'], true);
    });

    test('a coordinator reading is not the same as one creating', () async {
      // Listing needs a coordinator; creating needs a national admin. The
      // second refusal is the one the interface avoids by not offering it.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(403, {
          'error': {'code': 'FORBIDDEN', 'message': 'National admin required'},
        }),
      );

      final outcome = await CampaignsRepository(
        CampaignsApi(fakeDio(adapter)),
      ).create(const CampaignCreate(name: 'Nueva'));

      expect((outcome as CampaignRefused<CampaignOut>).isForbidden, isTrue);
    });
  });

  group('on screen', () {
    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      required FakeHttpAdapter adapter,
      bool coordinates = true,
      bool national = false,
    }) async {
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          canBrowseCampaignsProvider.overrideWithValue(coordinates),
          canManageCampaignsProvider.overrideWithValue(national),
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

    testWidgets('opening a campaign is not offered to whoever cannot', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [campaignJson()]),
      );

      await pump(tester, const CampaignsListView(), adapter: adapter);

      // Creating is a different role from reading, and the button is absent
      // rather than refused.
      expect(find.text('Nueva campaña'), findsNothing);
    });

    testWidgets('a national administration is offered to open one', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, [campaignJson()]),
      );

      await pump(
        tester,
        const CampaignsListView(),
        adapter: adapter,
        national: true,
      );

      expect(find.text('Nueva campaña'), findsOneWidget);
    });

    testWidgets('the general campaign says what it is, on its record', (
      tester,
    ) async {
      // `PROTECTED_CAMPAIGN` exists because nobody can be taken out of it.
      // Discovering that through a refusal is worse than reading it here.
      final adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('/members')) {
          return const FakeResponse(200, []);
        }
        return FakeResponse(200, campaignJson(isGeneral: true));
      });

      await pump(
        tester,
        const CampaignRecordView(campaignId: 'campaign-1'),
        adapter: adapter,
      );

      expect(find.text('General'), findsOneWidget);
      expect(find.textContaining('de aquí no se saca a nadie'), findsOneWidget);
    });

    testWidgets('a session that cannot browse is told, not shown an error', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(403, {
          'error': {'code': 'FORBIDDEN', 'message': 'Coordinator required'},
        }),
      );

      await pump(
        tester,
        const CampaignsListView(),
        adapter: adapter,
        coordinates: false,
      );

      expect(
        find.text('Solo quien coordina puede ver las campañas.'),
        findsOneWidget,
      );
    });

    testWidgets('the members of a campaign are named on its record', (
      tester,
    ) async {
      final adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('/members')) {
          return FakeResponse(200, [
            {
              'id': 'user-1',
              'email': 'ana@araguaney.lat',
              'username': 'ana',
              'full_name': 'Ana Pérez',
              'center_role': 'coordinator',
              'center_id': 'center-1',
              'is_active': true,
            },
          ]);
        }
        return FakeResponse(200, campaignJson());
      });

      await pump(
        tester,
        const CampaignRecordView(campaignId: 'campaign-1'),
        adapter: adapter,
      );

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.textContaining('Coordinación'), findsOneWidget);
    });
  });
}
