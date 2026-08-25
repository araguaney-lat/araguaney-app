import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/center/working_center.dart';
import 'package:araguaney_app/core/center/working_center_memory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const caracas = WorkingCenter(id: 'center-1', name: 'Caracas');
  const valencia = WorkingCenter(id: 'center-2', name: 'Valencia');

  ProviderContainer containerFor({
    required bool national,
    String? tokenCenterId,
    String? userId = 'user-1',
    WorkingCenterMemory? memory,
  }) {
    final container = ProviderContainer(
      overrides: [
        isNationalAdminProvider.overrideWithValue(national),
        myCenterIdProvider.overrideWithValue(tokenCenterId),
        sessionUserIdProvider.overrideWithValue(userId),
        workingCenterMemoryProvider.overrideWithValue(
          memory ?? InMemoryWorkingCenterMemory(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('remembering the choice', () {
    test('it is kept per person, because the device is shared', () async {
      final memory = InMemoryWorkingCenterMemory();
      await memory.write('user-1', caracas);

      expect(await memory.read('user-1'), caracas);
      // The shift that starts next does not inherit where the previous one was
      // writing.
      expect(await memory.read('user-2'), isNull);
    });

    test('choosing survives a restart', () async {
      final memory = InMemoryWorkingCenterMemory();
      final first = containerFor(national: true, memory: memory);
      await first.read(workingCenterProvider.future);
      await first.read(workingCenterProvider.notifier).choose(caracas);

      final second = containerFor(national: true, memory: memory);
      expect(await second.read(workingCenterProvider.future), caracas);
    });
  });

  group('what a create names', () {
    test('a session that belongs to a centre names none', () async {
      final container = containerFor(
        national: false,
        tokenCenterId: 'center-9',
      );
      await container.read(workingCenterProvider.future);

      // The server takes the centre from the token and ignores the body, so
      // sending one would suggest a coordinator can write somewhere else.
      expect(container.read(writeCenterIdProvider), isNull);
    });

    test('a national administrator names the chosen one', () async {
      final container = containerFor(national: true);
      await container.read(workingCenterProvider.future);
      await container.read(workingCenterProvider.notifier).choose(valencia);

      expect(container.read(writeCenterIdProvider), 'center-2');
    });
  });

  group('being asked', () {
    test('a national administrator with no centre is asked', () async {
      final container = containerFor(national: true);
      await container.read(workingCenterProvider.future);

      expect(container.read(needsWorkingCenterProvider), isTrue);
    });

    test('nobody is asked while the device is still being read', () {
      final container = containerFor(national: true);

      // «Not loaded yet» and «never chose» are different things, and only one
      // of them is a question. Asking during the read would flash the chooser
      // at somebody who already answered.
      expect(container.read(needsWorkingCenterProvider), isFalse);
    });

    test('once chosen, the question is over', () async {
      final container = containerFor(national: true);
      await container.read(workingCenterProvider.future);
      await container.read(workingCenterProvider.notifier).choose(caracas);

      expect(container.read(needsWorkingCenterProvider), isFalse);
    });

    test('a coordinator is never asked', () async {
      final container = containerFor(
        national: false,
        tokenCenterId: 'center-9',
      );
      await container.read(workingCenterProvider.future);

      expect(container.read(needsWorkingCenterProvider), isFalse);
    });
  });

  group('which centre is mine', () {
    test('the token wins when it carries one', () async {
      final container = containerFor(
        national: false,
        tokenCenterId: 'center-9',
      );
      await container.read(workingCenterProvider.future);

      expect(container.read(actingCenterIdProvider), 'center-9');
    });

    test('the chosen one answers for a session with no centre', () async {
      final container = containerFor(national: true);
      await container.read(workingCenterProvider.future);
      await container.read(workingCenterProvider.notifier).choose(caracas);

      expect(container.read(actingCenterIdProvider), 'center-1');
    });
  });
}
