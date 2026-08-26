import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/requests/data/requests_providers.dart';
import 'package:araguaney_app/features/requests/data/requests_repository.dart';
import 'package:araguaney_app/features/requests/ui/request_record_view.dart';
import 'package:araguaney_app/features/requests/ui/requests_list_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';

Map<String, Object?> requestJson({
  String id = 'r-1',
  String title = 'Nos quedamos sin suero',
  String description = 'Se acabó el suero fisiológico y llegan pacientes.',
  String status = 'OPEN',
  String createdAt = '2026-08-01T00:00:00Z',
  List<Map<String, Object?>> messages = const [],
}) => {
  'id': id,
  'author_id': 'u-1',
  'center_id': 'c-1',
  'title': title,
  'description': description,
  'status': status,
  'messages': messages,
  'created_at': createdAt,
  'updated_at': createdAt,
};

Map<String, Object?> messageJson({
  String id = 'm-1',
  String body = 'Tenemos dos cajas en el centro de Valencia.',
}) => {
  'id': id,
  'request_id': 'r-1',
  'author_id': 'u-2',
  'body': body,
  'created_at': '2026-08-02T00:00:00Z',
};

void main() {
  late List<RequestOptions> sent;

  setUp(() => sent = []);

  Future<void> pumpBoard(
    WidgetTester tester, {
    List<Map<String, Object?>> requests = const [],
    FakeResponse? listResponse,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      sent.add(options);
      if (options.method == 'POST') return FakeResponse(201, requestJson());
      return listResponse ?? FakeResponse(200, requests);
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
          home: RequestsListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpRecord(
    WidgetTester tester, {
    required Map<String, Object?> request,
    Object? matches = const <Object>[],
    bool canMoveStatus = false,
    FakeResponse? matchesResponse,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      sent.add(options);
      if (options.path.endsWith('/matches')) {
        return matchesResponse ?? FakeResponse(200, matches);
      }
      if (options.method == 'POST') return FakeResponse(201, messageJson());
      if (options.method == 'PATCH') {
        return FakeResponse(200, requestJson(status: 'IN_PROGRESS'));
      }
      return FakeResponse(200, request);
    });

    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        canMoveRequestStatusProvider.overrideWithValue(canMoveStatus),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RequestRecordView(requestId: 'r-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the board', () {
    testWidgets('what a centre asked for is on the board', (tester) async {
      await pumpBoard(tester, requests: [requestJson()]);

      expect(find.text('Nos quedamos sin suero'), findsOneWidget);
      expect(find.text('Una solicitud esperando'), findsOneWidget);
    });

    testWidgets('what is waiting comes before what was answered', (
      tester,
    ) async {
      // A request nobody has answered in a week is exactly the one being
      // forgotten, so the open half goes first and oldest at its top.
      await pumpBoard(
        tester,
        requests: [
          requestJson(
            id: 'r-old',
            title: 'Lo viejo',
            createdAt: '2026-07-01T00:00:00Z',
          ),
          requestJson(
            id: 'r-done',
            title: 'Lo atendido',
            status: 'RESOLVED',
            createdAt: '2026-07-20T00:00:00Z',
          ),
          requestJson(
            id: 'r-new',
            title: 'Lo reciente',
            createdAt: '2026-07-30T00:00:00Z',
          ),
        ],
      );

      final positions = [
        for (final title in ['Lo viejo', 'Lo reciente', 'Lo atendido'])
          tester.getTopLeft(find.text(title)).dy,
      ];

      expect(positions[0], lessThan(positions[1]));
      expect(positions[1], lessThan(positions[2]));
      expect(find.text('Ya atendidas'), findsOneWidget);
    });

    testWidgets('a request with no replies says nothing rather than zero', (
      tester,
    ) async {
      // «0 respuestas» reads as a figure; a silence reads as a silence.
      await pumpBoard(tester, requests: [requestJson()]);

      expect(find.textContaining('respuesta'), findsNothing);

      await pumpBoard(
        tester,
        requests: [
          requestJson(messages: [messageJson()]),
        ],
      );

      expect(find.text('1 respuesta'), findsOneWidget);
    });

    testWidgets('an empty board says so instead of showing nothing', (
      tester,
    ) async {
      await pumpBoard(tester);

      expect(
        find.text('Ningún centro ha pedido nada todavía.'),
        findsOneWidget,
      );
    });

    testWidgets('asking for something takes a subject and a sentence', (
      tester,
    ) async {
      // No quantities and no product: the contract asks for words, which is
      // what somebody standing in front of an empty shelf can write.
      await pumpBoard(tester);

      await tester.tap(find.text('Pedir algo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'Nos quedamos sin suero',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Se acabó el suero y llegan pacientes.',
      );
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();

      final post = sent.firstWhere((o) => o.method == 'POST');
      expect(post.path, '/v1/requests');
      expect((post.data as Map)['title'], 'Nos quedamos sin suero');
      expect(
        (post.data as Map)['description'],
        'Se acabó el suero y llegan pacientes.',
      );
    });

    testWidgets('a request with no subject is not sent', (tester) async {
      await pumpBoard(tester);

      await tester.tap(find.text('Pedir algo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();

      expect(sent.where((o) => o.method == 'POST'), isEmpty);
      expect(find.text('Escribe un asunto'), findsOneWidget);
    });
  });

  group('a request', () {
    testWidgets('the words of whoever wrote it are what is read', (
      tester,
    ) async {
      await pumpRecord(tester, request: requestJson());

      expect(find.text('Nos quedamos sin suero'), findsOneWidget);
      expect(
        find.text('Se acabó el suero fisiológico y llegan pacientes.'),
        findsOneWidget,
      );
      expect(find.text('Nadie ha respondido todavía.'), findsOneWidget);
    });

    testWidgets('what the platform has of it is shown when there is any', (
      tester,
    ) async {
      await pumpRecord(
        tester,
        request: requestJson(),
        matches: [
          {'category': 'MEDICINE', 'total_units': 120, 'box_count': 4},
        ],
      );

      expect(find.text('Lo que hay'), findsOneWidget);
      expect(find.text('Medicamentos'), findsOneWidget);
      expect(find.text('120 unidades · 4 cajas'), findsOneWidget);
    });

    testWidgets('with the matching off the section is simply not there', (
      tester,
    ) async {
      // The server answers an empty list when the capability is off, out of
      // budget or the provider did not reply. «No matches» would read as
      // «nobody has this», which is a stronger claim than the server made.
      await pumpRecord(tester, request: requestJson());

      expect(find.text('Lo que hay'), findsNothing);
    });

    testWidgets('a failed matching is not an error on the screen', (
      tester,
    ) async {
      await pumpRecord(
        tester,
        request: requestJson(),
        matchesResponse: FakeResponse(500, {
          'error': {'code': 'INTERNAL_ERROR', 'message': 'boom'},
        }),
      );

      expect(find.text('Lo que hay'), findsNothing);
      expect(find.text('boom'), findsNothing);
      expect(find.text('Nos quedamos sin suero'), findsOneWidget);
    });

    testWidgets('replying sends the text and empties the field', (
      tester,
    ) async {
      await pumpRecord(tester, request: requestJson());

      await tester.enterText(
        find.byType(TextField),
        'Tenemos dos cajas en Valencia.',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final post = sent.firstWhere((o) => o.method == 'POST');
      expect(post.path, '/v1/requests/r-1/messages');
      expect((post.data as Map)['body'], 'Tenemos dos cajas en Valencia.');
      expect(find.text('Tenemos dos cajas en Valencia.'), findsNothing);
    });

    testWidgets('an empty reply is not sent', (tester) async {
      await pumpRecord(tester, request: requestJson());

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(sent.where((o) => o.method == 'POST'), isEmpty);
    });

    testWidgets('what was answered is read on the record', (tester) async {
      await pumpRecord(tester, request: requestJson(messages: [messageJson()]));

      expect(
        find.text('Tenemos dos cajas en el centro de Valencia.'),
        findsOneWidget,
      );
    });

    testWidgets('moving the state is only offered to whoever may', (
      tester,
    ) async {
      // The backend gates this one route with `require_national_admin` while
      // the rest of the board only asks for a session.
      await pumpRecord(tester, request: requestJson());
      expect(find.text('Cambiar estado'), findsNothing);

      await pumpRecord(tester, request: requestJson(), canMoveStatus: true);
      expect(find.text('Cambiar estado'), findsOneWidget);
    });

    testWidgets('the four states are chosen, not typed', (tester) async {
      await pumpRecord(tester, request: requestJson(), canMoveStatus: true);

      await tester.tap(find.text('Cambiar estado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('En curso'));
      await tester.pumpAndSettle();

      final patch = sent.firstWhere((o) => o.method == 'PATCH');
      expect(patch.path, '/v1/requests/r-1/status');
      expect((patch.data as Map)['status'], 'IN_PROGRESS');
    });
  });

  group('what the matching answers', () {
    test('a row without its three fields is dropped, not filled in', () {
      // «No stock» and «the server did not say» are different answers, and
      // inventing a zero would turn the second into the first.
      expect(RequestMatch.tryFrom({'category': 'MEDICINE'}), isNull);
      expect(RequestMatch.tryFrom({'total_units': 3, 'box_count': 1}), isNull);
      expect(RequestMatch.tryFrom('MEDICINE'), isNull);

      final match = RequestMatch.tryFrom({
        'category': 'MEDICINE',
        'total_units': 120,
        'box_count': 4,
      });
      expect(match?.category, 'MEDICINE');
      expect(match?.totalUnits, 120);
      expect(match?.boxCount, 4);
    });
  });
}
