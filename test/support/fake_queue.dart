import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/features/intake/data/box_code_repository.dart';
import 'package:araguaney_app/features/intake/data/capture_queue_repository.dart';
import 'package:araguaney_app/features/intake/domain/intake_draft.dart';

import 'test_database.dart';

/// Doubles of the queue and of the code block, for the interface tests.
///
/// They exist because of a limitation of the environment, not out of
/// preference: in a `testWidgets` the clock is fake, and a real write to SQLite
/// fired from inside the widget tree never completes. What the real database
/// does is already covered against in-memory SQLite in the tests of
/// `capture_queue_test.dart` and `box_code_repository_test.dart`; what is
/// measured here is something else: what the screen does.
///
/// They extend the real classes instead of imitating an interface so the
/// signature cannot diverge in silence.
class FakeCaptureQueue extends CaptureQueueRepository {
  FakeCaptureQueue(AppDatabase database) : super(database: database);

  /// The captures the screen sent to the queue, in order.
  final enqueued = <({IntakeDraft draft, String userId})>[];

  @override
  Future<void> enqueue({
    required IntakeDraft draft,
    required String userId,
  }) async => enqueued.add((draft: draft, userId: userId));
}

class FakeBoxCodes extends BoxCodeRepository {
  FakeBoxCodes({required super.database, List<String>? pool})
    : pool = [...?pool],
      super(api: unusedBoxesApi());

  /// Available codes. It empties as they are handed out, like the real block.
  final List<String> pool;

  @override
  Future<List<String>> take(
    int count, {
    required String userId,
    String? centerId,
  }) async {
    final taken = pool.take(count).toList(growable: false);
    pool.removeRange(0, taken.length);
    return taken;
  }
}
