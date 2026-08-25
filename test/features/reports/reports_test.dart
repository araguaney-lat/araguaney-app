import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/export_job.dart';
import 'package:araguaney_app/core/api/generated/clients/dashboard_api.dart';
import 'package:araguaney_app/core/api/generated/clients/exports_api.dart';
import 'package:araguaney_app/core/api/generated/clients/reports_api.dart';
import 'package:araguaney_app/core/api/generated/models/report_summary.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/reports/data/reports_repository.dart';
import 'package:araguaney_app/features/reports/ui/reports_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Map<String, Object?> summaryJson({
    int totalBoxes = 40,
    int sealedBoxes = 30,
    int shippedBoxes = 10,
  }) => {
    'active_centers': 2,
    'draft_boxes': 4,
    'rejected_boxes': 1,
    'rejection_rate': 2.5,
    'sealed_boxes': sealedBoxes,
    'shipped_boxes': shippedBoxes,
    'total_boxes': totalBoxes,
    'total_intakes': 12,
    'total_shipments': 3,
    'total_units': 900,
  };

  Map<String, Object?> shrinkageJson({
    int reconciledBoxes = 20,
    double pct = 5.0,
  }) => {
    'damaged': 1,
    'missing': 1,
    'received': 18,
    'reconciled_boxes': reconciledBoxes,
    'retained': 0,
    'shrinkage_pct': pct,
  };

  FakeHttpAdapter reportsAdapter({
    Map<String, Object?>? summary,
    Map<String, Object?>? shrinkage,
    List<Map<String, Object?>>? byCategory,
    List<Map<String, Object?>>? activity,
    int summaryStatus = 200,
  }) => FakeHttpAdapter((options) {
    if (options.path.endsWith('/summary')) {
      return FakeResponse(
        summaryStatus,
        summaryStatus == 200
            ? (summary ?? summaryJson())
            : {
                'error': {'code': 'FORBIDDEN', 'message': 'no'},
              },
      );
    }
    if (options.path.endsWith('/shrinkage')) {
      return FakeResponse(200, shrinkage ?? shrinkageJson());
    }
    if (options.path.endsWith('/by-category')) {
      return FakeResponse(200, byCategory ?? const []);
    }
    if (options.path.endsWith('/activity')) {
      return FakeResponse(200, activity ?? const []);
    }
    if (options.path.endsWith('/countries')) return const FakeResponse(200, []);
    if (options.path.contains('/dashboard/weight')) {
      return const FakeResponse(200, {
        'campaigns': <Object?>[],
        'center_kg': null,
      });
    }
    return const FakeResponse(200, {});
  });

  ReportsRepository repositoryFor(FakeHttpAdapter adapter) => ReportsRepository(
    reports: ReportsApi(fakeDio(adapter)),
    dashboard: DashboardApi(fakeDio(adapter)),
    exports: ExportsApi(fakeDio(adapter)),
  );

  group('asking the server', () {
    test('every report hangs off the campaign it was asked about', () async {
      final adapter = reportsAdapter();
      final repository = repositoryFor(adapter);

      await repository.summary('campaign-1');
      await repository.shrinkage('campaign-1');
      await repository.byCategory('campaign-1');

      expect(adapter.requests.map((request) => request.path), [
        '/v1/reports/campaign/campaign-1/summary',
        '/v1/reports/campaign/campaign-1/shrinkage',
        '/v1/reports/campaign/campaign-1/by-category',
      ]);
    });

    test('not being in the campaign is a refusal, not a failure', () async {
      // `require_campaign_access` answers 403 to somebody who does not take
      // part, which is an expected answer.
      final outcome = await repositoryFor(
        reportsAdapter(summaryStatus: 403),
      ).summary('campaign-1');

      expect((outcome as ReportRefused<ReportSummary>).isForbidden, isTrue);
    });

    test('the export is a job, and the file is what comes back', () async {
      var asked = 0;
      final adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('export.csv')) {
          return const FakeResponse(202, {
            'id': 'job-1',
            'kind': 'campaign_csv',
            'status': 'PENDING',
          });
        }
        asked++;
        return FakeResponse(200, {
          'id': 'job-1',
          'kind': 'campaign_csv',
          'status': asked > 1 ? 'DONE' : 'PENDING',
          'download_url': asked > 1 ? 'https://files.invalid/a.csv' : null,
        });
      });

      final outcome = await repositoryFor(
        adapter,
      ).exportCsv('campaign-1', wait: (_) async {});

      expect(
        (outcome as DocumentReady).downloadUrl,
        'https://files.invalid/a.csv',
      );
    });
  });

  group('on screen', () {
    Future<void> pumpReports(
      WidgetTester tester, {
      required FakeHttpAdapter adapter,
      bool withCampaigns = true,
    }) async {
      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          writeCenterIdProvider.overrideWithValue(null),
          myCampaignsProvider.overrideWith(
            (ref) async => withCampaigns
                ? [campaign(id: 'campaign-1', name: 'Emergencia')]
                : const [],
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
            home: ReportsView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scrollTo(WidgetTester tester, Finder finder) async {
      // La pantalla es una sola columna larga: lo que no se ha desplazado
      // todavía ni siquiera está construido.
      await tester.dragUntilVisible(
        finder,
        find.byType(ListView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('with no campaign there is nothing to report', (tester) async {
      await pumpReports(
        tester,
        adapter: reportsAdapter(),
        withCampaigns: false,
      );

      expect(
        find.textContaining('No participas en ninguna campaña'),
        findsOneWidget,
      );
    });

    testWidgets('the numbers somebody acts on are the ones shown', (
      tester,
    ) async {
      await pumpReports(tester, adapter: reportsAdapter());

      expect(find.text('40'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Selladas'), findsOneWidget);
      // Ten numbers arrive and six are drawn: a nine-cell grid on a phone is a
      // grid nobody reads.
      expect(find.text('900'), findsNothing);
    });

    testWidgets('nothing reconciled says so instead of a zero per cent', (
      tester,
    ) async {
      await pumpReports(
        tester,
        adapter: reportsAdapter(
          shrinkage: shrinkageJson(reconciledBoxes: 0, pct: 0),
        ),
      );

      await scrollTo(
        tester,
        find.textContaining('Todavía no se cuadró ninguna recepción'),
      );
      expect(
        find.textContaining('Todavía no se cuadró ninguna recepción'),
        findsOneWidget,
      );
      expect(find.textContaining('% de merma'), findsNothing);
    });

    testWidgets('shrinkage names what is missing, damaged and retained', (
      tester,
    ) async {
      await pumpReports(tester, adapter: reportsAdapter());

      await scrollTo(tester, find.textContaining('5.0% de merma'));
      expect(find.textContaining('5.0% de merma'), findsOneWidget);
      expect(find.text('Faltantes: 1'), findsOneWidget);
      expect(find.text('Retenidas: 0'), findsOneWidget);
    });

    testWidgets('a cut list says it was cut', (tester) async {
      // Ten days arrive, seven are drawn. Cutting it in silence would read as
      // «that is all there was».
      await pumpReports(
        tester,
        adapter: reportsAdapter(
          activity: [
            for (var day = 1; day <= 10; day++)
              {
                'date': '2026-08-0$day',
                'draft': 0,
                'rejected': 0,
                'sealed': 1,
                'shipped': 0,
                'total': day,
              },
          ],
        ),
      );

      await scrollTo(
        tester,
        find.textContaining('Se muestran los 7 días más recientes de 10'),
      );
      expect(
        find.textContaining('Se muestran los 7 días más recientes de 10'),
        findsOneWidget,
      );
    });

    testWidgets('somebody outside the campaign is told, not alarmed', (
      tester,
    ) async {
      await pumpReports(tester, adapter: reportsAdapter(summaryStatus: 403));

      expect(
        find.text(
          'Solo quien participa en esta campaña puede ver sus informes.',
        ),
        findsOneWidget,
      );
    });
  });
}
