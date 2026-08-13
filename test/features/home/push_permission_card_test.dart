import 'package:araguaney_app/core/push/push_providers.dart';
import 'package:araguaney_app/core/push/push_service.dart';
import 'package:araguaney_app/features/home/ui/push_permission_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_push.dart';

void main() {
  late FakePushService push;

  setUp(() => push = FakePushService(token: 'fcm-1'));
  tearDown(() => push.dispose());

  Future<int> pumpCard(WidgetTester tester) async {
    var registered = 0;
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(push),
        onSessionStartedProvider.overrideWithValue(() async => registered++),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: PushPermissionCard())),
      ),
    );
    await tester.pumpAndSettle();
    return registered;
  }

  testWidgets('it says which notices arrive before asking for anything', (
    tester,
  ) async {
    // Un diálogo del sistema sin contexto se deniega por reflejo, y en Android
    // una denegación es casi definitiva.
    await pumpCard(tester);

    expect(find.text('Avisos del centro'), findsOneWidget);
    expect(find.textContaining('se abre una revisión'), findsOneWidget);
    expect(find.textContaining('llega un envío'), findsOneWidget);
    expect(push.permissionRequests, 0);
  });

  testWidgets('granting registers the device again', (tester) async {
    // En iOS el token no existe hasta que hay permiso, así que el registro de
    // la apertura de sesión no encontró ninguno.
    var registered = 0;
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(push),
        onSessionStartedProvider.overrideWithValue(() async => registered++),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: PushPermissionCard())),
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
    // El sabor `foss`. No hay permiso que pedir porque no hay avisos que
    // entregar.
    push.permissionStatus = PushPermission.unavailable;

    await pumpCard(tester);

    expect(find.text('Avisos del centro'), findsNothing);
  });
}
