import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/clients/messages_api.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/messaging/data/messaging_repository.dart';
import 'package:araguaney_app/features/messaging/ui/thread_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/l10n.dart';

void main() {
  group('the repository', () {
    MessagingRepository repositoryOn(FakeHttpAdapter adapter) =>
        MessagingRepository(MessagesApi(fakeDio(adapter)));

    test('replying sends the body to that thread', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, replyJson()));

      final outcome = await repositoryOn(
        adapter,
      ).reply(threadId: 'thread-1', body: 'Voy para allá');

      expect(outcome, isA<MessagingDone<void>>());
      expect(adapter.requests.single.path, '/v1/messages/thread-1/replies');
      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['body'], 'Voy para allá');
    });

    test('a new thread is opened as a campaign one', () async {
      // A private thread requires choosing recipients, which is desk work; from
      // the phone the campaign gets told.
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, threadJson()));

      await repositoryOn(adapter).openCampaignThread(
        campaignId: 'campaign-1',
        title: 'Faltan cajas',
        body: 'Nos quedamos sin cajas medianas',
      );

      final body = adapter.requests.single.data as Map<String, dynamic>;
      expect(body['thread_type'], 'PUBLIC');
      expect(body['campaign_id'], 'campaign-1');
      expect(body['title'], 'Faltan cajas');
    });

    test('a rejected thread keeps the server reason', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(403, {
          'error': {
            'code': 'FORBIDDEN',
            'message': 'No eres miembro de esta campaña',
          },
        }),
      );

      final outcome = await repositoryOn(
        adapter,
      ).openCampaignThread(campaignId: 'campaign-9', title: 'x', body: 'y');

      // The error translator shows the server's text only for business rules; a
      // 403 is told generically by design since phase 02. Here that costs
      // something concrete: «you are not a member of this campaign» would tell
      // the person what to ask for, and «you do not have permission» does not.
      expect(
        (outcome as MessagingRefused).failure.operatorMessage(await spanish()),
        'No tienes permiso para hacer esta operación.',
      );
    });

    test('marking read never throws', () async {
      // Opening a thread has to work even if the acknowledgement fails.
      await expectLater(
        repositoryOn(OfflineHttpAdapter()).markRead('thread-1'),
        completes,
      );
    });

    test('the unread count is the number the badge paints', () async {
      final adapter = FakeHttpAdapter((_) => FakeResponse(200, {'unread': 4}));

      expect(await repositoryOn(adapter).unreadCount(), 4);
    });
  });

  group('a thread on screen', () {
    Future<FakeHttpAdapter> pumpThread(
      WidgetTester tester, {
      bool replyFails = false,
    }) async {
      final adapter = FakeHttpAdapter((options) {
        if (options.path.endsWith('/replies')) {
          return replyFails
              ? FakeResponse(422, {
                  'error': {'code': 'RULE', 'message': 'El hilo está cerrado'},
                })
              : FakeResponse(201, replyJson());
        }
        if (options.path.endsWith('/read')) {
          return FakeResponse(200, const {});
        }
        return FakeResponse(
          200,
          threadDetailJson(
            body: 'Nos quedamos sin cajas medianas',
            replies: [replyJson(body: 'Salgo con veinte')],
          ),
        );
      });

      final container = ProviderContainer(
        overrides: [
          restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThreadView(threadId: 'thread-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return adapter;
    }

    testWidgets('shows the opening message and its replies', (tester) async {
      await pumpThread(tester);

      expect(find.text('Nos quedamos sin cajas medianas'), findsOneWidget);
      expect(find.text('Salgo con veinte'), findsOneWidget);
    });

    testWidgets('opening it marks it read', (tester) async {
      // If the counter went on counting what has been read, people would learn
      // to ignore it.
      final adapter = await pumpThread(tester);

      expect(
        adapter.requests.map((r) => r.path),
        contains('/v1/messages/thread-1/read'),
      );
    });

    testWidgets('a sent reply clears the field', (tester) async {
      await pumpThread(tester);

      await tester.enterText(find.byType(TextField), 'Voy para allá');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Voy para allá'), findsNothing);
    });

    testWidgets('a rejected reply keeps what was written', (tester) async {
      // Losing what was written to a failure would be the worst way to answer
      // somebody who already wrote.
      await pumpThread(tester, replyFails: true);

      await tester.enterText(find.byType(TextField), 'Voy para allá');
      await tester.tap(find.byTooltip('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('Voy para allá'), findsOneWidget);
      expect(find.text('El hilo está cerrado'), findsOneWidget);
    });
  });
}
