import 'dart:convert';

import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/center/working_center.dart';
import 'package:araguaney_app/core/center/working_center_memory.dart';
import 'package:araguaney_app/core/db/app_database.dart';
import 'package:araguaney_app/core/db/db_providers.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/intake/domain/box_draft_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';
import '../../support/test_database.dart';

void main() {
  const caracas = WorkingCenter(id: 'center-1', name: 'Caracas');
  const valencia = WorkingCenter(id: 'center-2', name: 'Valencia');

  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  ProviderContainer containerFor({
    required bool national,
    String? tokenCenterId,
  }) {
    final container = ProviderContainer(
      overrides: [
        isNationalAdminProvider.overrideWithValue(national),
        myCenterIdProvider.overrideWithValue(tokenCenterId),
        sessionUserIdProvider.overrideWithValue('user-1'),
        workingCenterMemoryProvider.overrideWithValue(
          InMemoryWorkingCenterMemory(),
        ),
        captureIdGeneratorProvider.overrideWithValue(() => 'capture-fixed'),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('a capture from a national session names the working centre', () async {
    final container = containerFor(national: true);
    await container.read(workingCenterProvider.future);
    await container.read(workingCenterProvider.notifier).choose(caracas);

    final draft = container.read(intakeDraftControllerProvider);

    expect(draft.toRequest().centerId, 'center-1');
  });

  test('a capture from a centre session names none', () async {
    final container = containerFor(national: false, tokenCenterId: 'center-9');
    await container.read(workingCenterProvider.future);

    // Whatever this sent would be ignored, and offering the field would say
    // otherwise.
    expect(
      container.read(intakeDraftControllerProvider).toRequest().centerId,
      isNull,
    );
  });

  test('changing centre does not move a capture already queued', () async {
    final container = containerFor(national: true);
    await container.read(workingCenterProvider.future);
    await container.read(workingCenterProvider.notifier).choose(caracas);

    final controller = container.read(intakeDraftControllerProvider.notifier)
      ..addBox(
        BoxDraftInput(
          productType: productTypeRow(),
          quantity: 10,
          unit: 'unidad',
        ),
      );
    await controller.enqueue('user-1');

    // Somebody finishes in Caracas, walks to Valencia and switches. The boxes
    // already put down in Caracas were registered there.
    await container.read(workingCenterProvider.notifier).choose(valencia);

    final row = (await db.captureQueueDao.pending('user-1')).single;
    final payload = jsonDecode(row.payload) as Map<String, Object?>;
    expect(payload['center_id'], 'center-1');
  });
}
