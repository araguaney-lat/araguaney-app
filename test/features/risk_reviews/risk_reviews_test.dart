import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/risk_reviews_api.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/features/risk_reviews/data/risk_reviews_repository.dart';
import 'package:araguaney_app/features/risk_reviews/ui/risk_reviews_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  group('the repository', () {
    RiskReviewsRepository repositoryOn(FakeHttpAdapter adapter) =>
        RiskReviewsRepository(RiskReviewsApi(fakeDio(adapter)));

    test('resolving sends the decision and the note', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, riskReviewJson()),
      );

      final outcome = await repositoryOn(adapter).resolve(
        reviewId: 'rr-1',
        resolution: RiskResolution.approve,
        note: 'Se verificó con el donante',
      );

      expect(outcome, isA<ReviewResolved>());
      expect(adapter.requests.single.path, '/v1/risk-reviews/rr-1/resolve');
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['resolution'], 'APPROVED');
      expect(body['note'], 'Se verificó con el donante');
    });

    test('a note is optional', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(200, riskReviewJson()),
      );

      await repositoryOn(
        adapter,
      ).resolve(reviewId: 'rr-1', resolution: RiskResolution.reject);

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['note'], isNull);
    });

    test('one already resolved elsewhere says exactly that', () async {
      // Que alguien la haya cerrado desde el panel mientras esta pantalla
      // estaba abierta es el caso normal, no una rareza.
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(409, {
          'error': {
            'code': 'ALREADY_RESOLVED',
            'message': 'Esta revisión ya fue resuelta',
          },
        }),
      );

      final outcome = await repositoryOn(
        adapter,
      ).resolve(reviewId: 'rr-1', resolution: RiskResolution.approve);

      expect(
        (outcome as ResolveRefused).failure.operatorMessage,
        'Esta revisión ya fue resuelta',
      );
    });
  });

  group('the screen', () {
    Future<FakeHttpAdapter> pumpReviews(
      WidgetTester tester, {
      required bool canResolve,
    }) async {
      final adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('/resolve')) {
          return FakeResponse(200, riskReviewJson());
        }
        return FakeResponse(200, [
          riskReviewJson(
            id: 'rr-1',
            reason: 'Volumen inusual para una donación anónima',
          ),
        ]);
      });

      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
          isCenterCoordinatorProvider.overrideWithValue(canResolve),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: RiskReviewsView()),
        ),
      );
      await tester.pumpAndSettle();
      return adapter;
    }

    testWidgets('coordination can close a review, with the reason in view', (
      tester,
    ) async {
      final adapter = await pumpReviews(tester, canResolve: true);

      await tester.tap(find.text('Resolver'));
      await tester.pumpAndSettle();

      // El motivo sigue delante mientras se decide.
      expect(
        find.text('Volumen inusual para una donación anónima'),
        findsWidgets,
      );

      await tester.enterText(find.byType(TextField), 'Se verificó');
      await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
      await tester.pumpAndSettle();

      final resolve = adapter.requests.firstWhere(
        (r) => r.path.endsWith('/resolve'),
      );
      final body = resolve.data as Map<String, dynamic>;
      expect(body['resolution'], 'APPROVED');
      expect(body['note'], 'Se verificó');
    });

    testWidgets('rejecting is offered with the same weight as approving', (
      tester,
    ) async {
      // Esconderla detrás de un paso más haría de la decisión difícil la
      // incómoda.
      await pumpReviews(tester, canResolve: true);

      await tester.tap(find.text('Resolver'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Rechazar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Aprobar'), findsOneWidget);
    });

    testWidgets('a volunteer reads the reason but cannot close it', (
      tester,
    ) async {
      await pumpReviews(tester, canResolve: false);

      expect(
        find.text('Volumen inusual para una donación anónima'),
        findsOneWidget,
      );
      expect(find.text('Resolver'), findsNothing);
    });
  });
}
