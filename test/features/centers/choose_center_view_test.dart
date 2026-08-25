import 'package:araguaney_app/core/api/generated/models/center_out.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/center/center_providers.dart';
import 'package:araguaney_app/core/center/working_center_memory.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/centers/data/centers_providers.dart';
import 'package:araguaney_app/features/centers/data/centers_repository.dart';
import 'package:araguaney_app/features/centers/ui/choose_center_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  CenterOut center({
    required String id,
    required String name,
    bool isActive = true,
  }) => CenterOut(
    id: id,
    name: name,
    isActive: isActive,
    address: null,
    contactEmail: null,
    contactName: null,
    contactPhone: null,
    countryCode: 'VE',
    createdAt: testNow,
    stateName: 'Miranda',
  );

  Future<ProviderContainer> pumpChooser(
    WidgetTester tester, {
    required List<CenterOut> centers,
  }) async {
    final container = ProviderContainer(
      overrides: [
        isNationalAdminProvider.overrideWithValue(true),
        myCenterIdProvider.overrideWithValue(null),
        sessionUserIdProvider.overrideWithValue('user-1'),
        workingCenterMemoryProvider.overrideWithValue(
          InMemoryWorkingCenterMemory(),
        ),
        centersProvider.overrideWith((ref) async => CentersRead(centers)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChooseCenterView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('it says what the choice decides', (tester) async {
    await pumpChooser(
      tester,
      centers: [center(id: 'c1', name: 'Caracas')],
    );

    expect(find.text('¿En qué centro vas a operar?'), findsOneWidget);
    expect(
      find.textContaining('queda en el centro que elijas'),
      findsOneWidget,
    );
  });

  testWidgets('a closed centre is not offered', (tester) async {
    // Nobody is receiving donations there today, and the server would refuse
    // the first thing registered into it.
    await pumpChooser(
      tester,
      centers: [
        center(id: 'c1', name: 'Caracas'),
        center(id: 'c2', name: 'Valencia', isActive: false),
      ],
    );

    expect(find.text('Caracas'), findsOneWidget);
    expect(find.text('Valencia'), findsNothing);
  });

  testWidgets('choosing one is what a capture will name', (tester) async {
    final container = await pumpChooser(
      tester,
      centers: [
        center(id: 'c1', name: 'Caracas'),
        center(id: 'c2', name: 'Valencia'),
      ],
    );

    await tester.tap(find.text('Valencia'));
    await tester.pumpAndSettle();

    expect(container.read(writeCenterIdProvider), 'c2');
  });

  testWidgets('with no active centre it says so instead of an empty list', (
    tester,
  ) async {
    await pumpChooser(tester, centers: const []);

    expect(find.text('No hay centros activos.'), findsOneWidget);
  });
}
