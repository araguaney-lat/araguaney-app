import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/center/working_center.dart';
import 'package:araguaney_app/core/center/working_center_memory.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/core/ui/working_center_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    required bool national,
    String? tokenCenterId,
    WorkingCenter? chosen,
  }) async {
    final memory = InMemoryWorkingCenterMemory();
    if (chosen != null) await memory.write('user-1', chosen);

    final container = ProviderContainer(
      overrides: [
        isNationalAdminProvider.overrideWithValue(national),
        myCenterIdProvider.overrideWithValue(tokenCenterId),
        sessionUserIdProvider.overrideWithValue('user-1'),
        workingCenterMemoryProvider.overrideWithValue(memory),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WorkingCenterBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('it names the centre the work is being written into', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      national: true,
      chosen: const WorkingCenter(id: 'c1', name: 'Caracas'),
    );

    expect(find.text('Registrando en Caracas'), findsOneWidget);
  });

  testWidgets('a session with one centre is told nothing', (tester) async {
    // A permanent reminder of something that cannot vary is noise, and noise
    // is what trains people to stop reading banners.
    await pumpBanner(tester, national: false, tokenCenterId: 'center-9');

    expect(find.byType(Text), findsNothing);
  });
}
