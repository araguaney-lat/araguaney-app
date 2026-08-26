import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/center_applications/ui/application_queue_view.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';

Map<String, Object?> applicationJson({
  String id = 'a-1',
  String centerName = 'Fundación Manos del Táchira',
  String contactName = 'Rosa Guerrero',
  String contactEmail = 'rosa@manostachira.org',
  String? backingOrg = 'Diócesis de San Cristóbal',
  String? message = 'Operamos desde 2019 con un depósito propio.',
  String? state = 'Táchira',
}) => {
  'id': id,
  'center_name': centerName,
  'country_code': 'VE',
  'state_name': state,
  'address': 'Calle 4',
  'contact_name': contactName,
  'contact_email': contactEmail,
  'contact_phone': '+58 000',
  'backing_org': backingOrg,
  'social_url': '@manostachira',
  'message': message,
  'status': 'PENDING_REVIEW',
  'email_verified_at': '2026-08-15T00:00:00Z',
  'reviewed_at': null,
  'reject_reason': null,
  'created_center_id': null,
  'created_at': '2026-08-15T00:00:00Z',
};

void main() {
  late List<RequestOptions> sent;

  setUp(() => sent = []);

  Future<void> pumpQueue(
    WidgetTester tester, {
    List<Map<String, Object?>> queue = const [],
    FakeResponse? queueResponse,
  }) async {
    final adapter = FakeHttpAdapter((options) {
      sent.add(options);
      if (options.method == 'POST') return FakeResponse(200, applicationJson());
      return queueResponse ?? FakeResponse(200, queue);
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
          home: ApplicationQueueView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('everything the decision rests on is on the card', (
    tester,
  ) async {
    // Forcing a record to be opened to know who backs a centre turns a queue of
    // three into three navigations.
    await pumpQueue(tester, queue: [applicationJson()]);

    expect(find.text('Fundación Manos del Táchira'), findsOneWidget);
    expect(find.textContaining('Rosa Guerrero'), findsOneWidget);
    expect(find.text('Diócesis de San Cristóbal'), findsOneWidget);
    expect(find.textContaining('Operamos desde 2019'), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
  });

  testWidgets('the applicant\'s words are quoted, not paraphrased', (
    tester,
  ) async {
    await pumpQueue(tester, queue: [applicationJson()]);

    expect(
      find.text('«Operamos desde 2019 con un depósito propio.»'),
      findsOneWidget,
    );
  });

  testWidgets('approving names its three consequences before doing them', (
    tester,
  ) async {
    // A confirmation that only says «are you sure?» informs nobody of anything,
    // and this creates a centre, adds a person and sends them a password.
    await pumpQueue(tester, queue: [applicationJson()]);

    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Se crea el centro'), findsOneWidget);
    expect(find.textContaining('coordinación'), findsOneWidget);
    // Twice: on the card and in the confirmation. What matters is that the
    // dialog says which address the password is going to arrive at.
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.textContaining('rosa@manostachira.org'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('No se puede deshacer'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    await pumpQueue(tester, queue: [applicationJson()]);

    await tester.tap(find.text('Aprobar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(sent.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('rejecting says where the reason is going', (tester) async {
    // What is written is read by whoever applied, in an email, with no further
    // context.
    await pumpQueue(tester, queue: [applicationJson()]);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('se le envía por correo'), findsOneWidget);
  });

  testWidgets('a rejection without a reason does not leave', (tester) async {
    // The server requires it too, but going all the way there for it to say so
    // would spend a request and a wait.
    await pumpQueue(tester, queue: [applicationJson()]);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el motivo del rechazo'), findsOneWidget);
    expect(sent.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('a written reason travels as the person typed it', (
    tester,
  ) async {
    await pumpQueue(tester, queue: [applicationJson()]);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Falta el respaldo institucional.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Rechazar'));
    await tester.pumpAndSettle();

    final post = sent.firstWhere((r) => r.method == 'POST');
    expect(post.path, contains('/reject'));
    expect((post.data as Map)['reason'], 'Falta el respaldo institucional.');
  });

  testWidgets('an empty queue says so rather than showing nothing', (
    tester,
  ) async {
    await pumpQueue(tester, queue: []);

    expect(
      find.text('Ninguna postulación espera una decisión.'),
      findsOneWidget,
    );
  });

  testWidgets('a refusal is read as an answer, not an error', (tester) async {
    // Reviewing applications has a role of its own; whoever lacks it should be
    // told who can, not shown a failure.
    await pumpQueue(
      tester,
      queueResponse: FakeResponse(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'Reviewer access required'},
      }),
    );

    expect(
      find.textContaining('Solo quien revisa postulaciones'),
      findsOneWidget,
    );
  });

  testWidgets('a centre with nothing optional shows no empty labels', (
    tester,
  ) async {
    // The generated model brings these fields nullable: what does not arrive is
    // omitted.
    await pumpQueue(
      tester,
      queue: [applicationJson(backingOrg: null, message: null, state: null)],
    );

    expect(find.text('Respaldo'), findsNothing);
    expect(find.textContaining('«'), findsNothing);
  });
}
