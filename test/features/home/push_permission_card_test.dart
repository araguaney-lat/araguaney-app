import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/push/push_service.dart';
import 'package:araguaney_app/features/home/ui/push_permission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_push.dart';
import '../../support/fake_push_prompt_memory.dart';

void main() {
  late FakePushService push;
  late FakePushPromptMemory memory;

  setUp(() {
    push = FakePushService(token: 'fcm-1');
    memory = FakePushPromptMemory();
  });
  tearDown(() => push.dispose());

  Future<int> pumpCard(WidgetTester tester) async {
    var registered = 0;
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(push),
        pushPromptMemoryProvider.overrideWithValue(memory),
        onSessionStartedProvider.overrideWithValue(() async => registered++),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PushPermissionCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return registered;
  }

  testWidgets('it says which notices arrive before asking for anything', (
    tester,
  ) async {
    // A system dialog with no context is denied by reflex, and on Android a
    // denial is close to final.
    await pumpCard(tester);

    expect(find.text('Avisos del centro'), findsOneWidget);
    expect(find.textContaining('se abre una revisión'), findsOneWidget);
    expect(find.textContaining('llega un envío'), findsOneWidget);
    expect(push.permissionRequests, 0);
  });

  testWidgets('granting registers the device again', (tester) async {
    // On iOS the token does not exist until there is permission, so the
    // registration at sign-in found none.
    var registered = 0;
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(push),
        pushPromptMemoryProvider.overrideWithValue(memory),
        onSessionStartedProvider.overrideWithValue(() async => registered++),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PushPermissionCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activar avisos'));
    await tester.pumpAndSettle();

    expect(push.permissionRequests, 1);
    expect(registered, 1);
    expect(find.text('Activar avisos'), findsNothing);
  });

  testWidgets('denying does not leave a card insisting', (tester) async {
    push.answerWhenAsked = PushPermission.denied;
    await pumpCard(tester);

    await tester.tap(find.text('Activar avisos'));
    await tester.pumpAndSettle();

    expect(find.text('Avisos del centro'), findsNothing);
  });

  testWidgets('a build with no notifications shows nothing at all', (
    tester,
  ) async {
    // The `foss` flavour. There is no permission to ask for because there are
    // no notices to deliver.
    push.permissionStatus = PushPermission.unavailable;

    await pumpCard(tester);

    expect(find.text('Avisos del centro'), findsNothing);
  });

  testWidgets('Android offers it even though the system says denied', (
    tester,
  ) async {
    // The case that left the card dead: `firebase_messaging` on Android never
    // answers `notDetermined`, so without a memory of our own the invitation
    // never appeared and nobody got to see the system dialog.
    push.permissionStatus = PushPermission.denied;

    await pumpCard(tester);

    expect(find.text('Avisos del centro'), findsOneWidget);
  });

  testWidgets('what was already offered is not offered again', (tester) async {
    push.permissionStatus = PushPermission.denied;
    memory = FakePushPromptMemory(offered: true);

    await pumpCard(tester);

    expect(find.text('Avisos del centro'), findsNothing);
  });

  testWidgets('offering is remembered before the system dialog opens', (
    tester,
  ) async {
    // If the system dialog takes the application down with it, the person has
    // already seen the invitation; putting it in front of them again would be
    // insisting.
    await pumpCard(tester);

    await tester.tap(find.text('Activar avisos'));
    await tester.pumpAndSettle();

    expect(memory.offered, isTrue);
  });
}
