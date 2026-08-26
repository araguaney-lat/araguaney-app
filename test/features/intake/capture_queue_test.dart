import 'dart:convert';

import 'package:araguaney_app/core/api/generated/clients/intakes_api.dart';
import 'package:araguaney_app/core/api/refusal_copy.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/daos/sync_markers_dao.dart';
import 'package:araguaney_app/core/db/tables/queued_captures_table.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_sync.dart';
import 'package:araguaney_app/features/intake/domain/box_draft_input.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/l10n.dart';
import '../../support/test_database.dart';

IntakeDraft draftWith({
  String captureId = 'capture-1',
  int quantity = 10,
  String? donanteLibre,
}) => IntakeDraft(captureId: captureId, donanteLibre: donanteLibre).addBox(
  BoxDraftInput(
    productType: productTypeRow(),
    quantity: quantity,
    unit: 'unidad',
  ),
);

void main() {
  late AppDatabase db;
  late CaptureQueueRepository queue;

  setUp(() {
    db = openTestDatabase();
    queue = CaptureQueueRepository(database: db, now: () => testNow);
  });

  tearDown(() => db.close());

  CaptureQueueSync syncOn(FakeHttpAdapter adapter) => CaptureQueueSync(
    api: IntakesApi(fakeDio(adapter)),
    database: db,
    now: () => testNow,
  );

  group('invariant 1 — the idempotency key never changes', () {
    test('the queued payload carries the key it was created with', () async {
      await queue.enqueue(draft: draftWith(), userId: 'user-1');

      final row = await db.captureQueueDao.findById('capture-1');
      final payload = jsonDecode(row!.payload) as Map<String, Object?>;
      expect(payload['capture_id'], 'capture-1');
    });

    test('enqueueing the same capture twice does not duplicate it', () async {
      // The primary key stops it, not a check somebody can forget: two taps of
      // the send button are a single capture.
      await queue.enqueue(draft: draftWith(quantity: 10), userId: 'user-1');
      await queue.enqueue(draft: draftWith(quantity: 99), userId: 'user-1');

      final rows = await queue.watchAll('user-1').first;
      expect(rows, hasLength(1));
      final payload = jsonDecode(rows.single.payload) as Map<String, Object?>;
      expect((payload['boxes'] as List).single, containsPair('quantity', 10));
    });

    test('every retry sends the same key', () async {
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      var attempts = 0;
      final adapter = FakeHttpAdapter((_) {
        attempts++;
        return attempts == 1
            ? FakeResponse(503, {
                'error': {'code': 'SERVICE_UNAVAILABLE', 'message': 'caído'},
              })
            : FakeResponse(201, intakeJson());
      });
      final sync = syncOn(adapter);

      await sync.flush('user-1');
      await sync.flush('user-1');

      final keys = adapter.requests
          .map((r) => (r.data as Map<String, dynamic>)['capture_id'])
          .toList();
      expect(keys, ['capture-1', 'capture-1']);
    });
  });

  group('invariant 3 — the queue belongs to whoever captured', () {
    test('flushing one session never sends another persons captures', () async {
      await queue.enqueue(
        draft: draftWith(captureId: 'morning'),
        userId: 'a',
      );
      await queue.enqueue(
        draft: draftWith(captureId: 'evening'),
        userId: 'b',
      );
      final adapter = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));

      final report = await syncOn(adapter).flush('b');

      expect(report.sent, 1);
      final sentKey =
          (adapter.requests.single.data as Map<String, dynamic>)['capture_id'];
      expect(sentKey, 'evening');
      expect(await db.captureQueueDao.findById('morning'), isNotNull);
    });

    test('the pending count is each persons own', () async {
      await queue.enqueue(
        draft: draftWith(captureId: 'a-1'),
        userId: 'a',
      );
      await queue.enqueue(
        draft: draftWith(captureId: 'a-2'),
        userId: 'a',
      );
      await queue.enqueue(
        draft: draftWith(captureId: 'b-1'),
        userId: 'b',
      );

      expect(await queue.watchPendingCount('a').first, 2);
      expect(await queue.watchPendingCount('b').first, 1);
    });

    test(
      'a change of shift does not wipe what the previous one captured',
      () async {
        // `clearReadModel` runs when another person signs in. That it does not
        // touch the queue is the feature: what was captured in a basement stays
        // pending.
        await queue.enqueue(draft: draftWith(), userId: 'user-1');
        await db.boxCodesDao.store(
          ['BX-RESERVED'],
          userId: 'user-1',
          at: testNow,
        );
        await db.catalogDao.replaceAll([productTypeRow()]);
        await db.syncMarkersDao.markSynced(SyncResource.boxes, testNow);

        await db.clearReadModel();

        expect(await queue.watchAll('user-1').first, hasLength(1));
        expect(await db.boxCodesDao.available('user-1'), 1);
        // And it does delete what really is cache.
        expect(await db.catalogDao.all(), isEmpty);
      },
    );
  });

  group('invariant 4 — nothing is discarded on its own', () {
    test(
      'a parked capture can be sent back to the queue by a person',
      () async {
        await queue.enqueue(draft: draftWith(), userId: 'user-1');
        await syncOn(
          FakeHttpAdapter(
            (_) => FakeResponse(422, {
              'error': {
                'code': 'NOT_CAMPAIGN_MEMBER',
                'message': 'No perteneces a esa campaña',
              },
            }),
          ),
        ).flush('user-1');

        // Parking means it stops retrying by itself. When the reason is
        // resolved outside, the right way out is going back to the queue and
        // not throwing inventory away.
        await queue.retry('capture-1');

        final row = await db.captureQueueDao.findById('capture-1');
        expect(row?.status, QueuedCaptureStatus.pending);
        expect(row?.lastFailureMessage, isNull);
        // The attempts happened: retrying does not erase them.
        expect(row?.attempts, 1);
      },
    );

    test('retrying sends the same capture id, so nothing duplicates', () async {
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      await syncOn(
        FakeHttpAdapter(
          (_) => FakeResponse(422, {
            'error': {'code': 'NOT_CAMPAIGN_MEMBER', 'message': 'No.'},
          }),
        ),
      ).flush('user-1');

      await queue.retry('capture-1');
      final accepted = FakeHttpAdapter((_) => FakeResponse(201, intakeJson()));
      final report = await syncOn(accepted).flush('user-1');

      expect(report.sent, 1);
      final body = accepted.requests.single.data as Map<String, dynamic>;
      expect(body['capture_id'], 'capture-1');
      expect(await db.captureQueueDao.findById('capture-1'), isNull);
    });

    test(
      'a business rejection parks the capture with the server reason',
      () async {
        await queue.enqueue(draft: draftWith(), userId: 'user-1');
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(422, {
            'error': {
              'code': 'SHELF_LIFE_TOO_SHORT',
              'message': 'La caducidad no alcanza el mínimo de la campaña',
            },
          }),
        );

        final report = await syncOn(adapter).flush('user-1');

        expect(report.parked, 1);
        final row = await db.captureQueueDao.findById('capture-1');
        expect(row?.status, QueuedCaptureStatus.rejected);
        expect(
          row?.lastFailureMessage,
          'La caducidad no alcanza el mínimo de la campaña',
        );
      },
    );

    test('a capture refused by campaign says how to unblock it', () async {
      // The server names that rule (`NOT_CAMPAIGN_MEMBER`), and whoever
      // captured can resolve it by asking to be added. A generic «you do not
      // have permission» would leave the capture stuck without saying what to
      // do with it.
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(403, {
          'error': {
            'code': 'NOT_CAMPAIGN_MEMBER',
            'message': 'User is not assigned to this campaign',
          },
        }),
      );

      final report = await syncOn(adapter).flush('user-1');

      expect(report.parked, 1);
      final row = await db.captureQueueDao.findById('capture-1');
      // **The code and the server's words are stored, not our own copy.** What
      // is stored is read by somebody days later, perhaps with the application
      // in another language; writing today's rendering here would freeze a
      // language into the database. The screen resolves it from the code.
      expect(row?.lastFailureCode, 'NOT_CAMPAIGN_MEMBER');
      expect(row?.lastFailureMessage, 'User is not assigned to this campaign');
      expect(
        refusalCopyFor(await spanish(), row!.lastFailureCode!),
        contains('Pide que te sumen'),
      );
    });

    test('a parked capture is not retried again', () async {
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(422, {
          'error': {'code': 'RULE', 'message': 'no'},
        }),
      );
      final sync = syncOn(adapter);

      await sync.flush('user-1');
      await sync.flush('user-1');

      // Retrying something already refused gives the same answer forever.
      expect(adapter.requests, hasLength(1));
    });

    test('a spent code parks the capture instead of closing it', () async {
      // Idempotency by `capture_id` is checked before the codes, so this error
      // means the capture was NOT registered and its label is stuck on another
      // box. Closing it by itself would lose inventory.
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(409, {
          'error': {
            'code': 'CODE_ALREADY_USED',
            'message': 'El código BX-0001 ya fue usado',
            'field': 'code',
          },
        }),
      );

      await syncOn(adapter).flush('user-1');

      final row = await db.captureQueueDao.findById('capture-1');
      expect(row, isNotNull);
      expect(row?.status, QueuedCaptureStatus.rejected);
      expect(row?.lastFailureCode, 'CODE_ALREADY_USED');
    });

    test(
      'discarding is explicit and only then does the row disappear',
      () async {
        await queue.enqueue(draft: draftWith(), userId: 'user-1');

        await queue.discard('capture-1');

        expect(await queue.watchAll('user-1').first, isEmpty);
      },
    );
  });

  group('flushing', () {
    test('an accepted capture leaves the queue', () async {
      await queue.enqueue(draft: draftWith(), userId: 'user-1');

      final report = await syncOn(
        FakeHttpAdapter((_) => FakeResponse(201, intakeJson())),
      ).flush('user-1');

      expect(report.sent, 1);
      expect(await queue.watchAll('user-1').first, isEmpty);
    });

    test('no signal stops the flush and keeps everything pending', () async {
      await queue.enqueue(
        draft: draftWith(captureId: 'c-1'),
        userId: 'user-1',
      );
      await queue.enqueue(
        draft: draftWith(captureId: 'c-2'),
        userId: 'user-1',
      );
      final adapter = OfflineHttpAdapter();

      final report = await syncOn(adapter).flush('user-1');

      // A single request: with no network, trying the second would give the
      // same error.
      expect(adapter.requests, hasLength(1));
      expect(report.sent, 0);
      expect(report.remaining, 2);
      expect(report.stoppedBy?.isRetryable, isTrue);
    });

    test('an expired session does not park anything', () async {
      // A 401 says nothing bad about the capture: it says the session expired.
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(401, {
          'error': {'code': 'UNAUTHORIZED', 'message': 'sesión vencida'},
        }),
      );

      final report = await syncOn(adapter).flush('user-1');

      expect(report.parked, 0);
      expect(report.remaining, 1);
      expect(
        (await db.captureQueueDao.findById('capture-1'))?.status,
        QueuedCaptureStatus.pending,
      );
    });

    test('a rejection does not stop the ones behind it', () async {
      await queue.enqueue(
        draft: draftWith(captureId: 'c-1'),
        userId: 'user-1',
      );
      await queue.enqueue(
        draft: draftWith(captureId: 'c-2'),
        userId: 'user-1',
      );
      var calls = 0;
      final adapter = FakeHttpAdapter((_) {
        calls++;
        return calls == 1
            ? FakeResponse(422, {
                'error': {'code': 'RULE', 'message': 'no'},
              })
            : FakeResponse(201, intakeJson());
      });

      final report = await syncOn(adapter).flush('user-1');

      expect(report.parked, 1);
      expect(report.sent, 1);
    });

    test('attempts are counted', () async {
      await queue.enqueue(draft: draftWith(), userId: 'user-1');
      final sync = syncOn(OfflineHttpAdapter());

      await sync.flush('user-1');
      await sync.flush('user-1');

      expect((await db.captureQueueDao.findById('capture-1'))?.attempts, 2);
    });
  });

  group('the summary stored while it waits', () {
    test('names what and for whom, and counts nothing', () async {
      // The count is a column of its own, and the words for it are rendered
      // when the screen is drawn. Writing «1 caja» into the row would freeze
      // today's language into something read days later.
      await queue.enqueue(
        draft: draftWith(donanteLibre: 'Vecinos del barrio'),
        userId: 'user-1',
      );

      final row = await db.captureQueueDao.findById('capture-1');
      expect(row?.summary, 'Paracetamol 500 mg · Vecinos del barrio');
      expect(row?.boxCount, 1);
    });
  });
}
