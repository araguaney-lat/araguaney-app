import 'package:araguaney_app/core/api/generated/models/intake_out.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/intake/data/intake_providers.dart';
import 'package:araguaney_app/features/intake/ui/intake_detail_view.dart';
import 'package:araguaney_app/features/intake/ui/intake_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpList(WidgetTester tester, List<IntakeOut> intakes) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [intakesProvider.overrideWith((ref) async => intakes)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: IntakeListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// `GET /v1/intakes` declares `boxes` with an empty list by default and the
  /// server does not fill it in when listing, so this is what really arrives.
  IntakeOut listed() => IntakeOut.fromJson(intakeJson(boxes: []));

  testWidgets('the listing does not invent a box count it was not sent', (
    tester,
  ) async {
    await pumpList(tester, [listed()]);

    expect(find.text('0 cajas'), findsNothing);
  });

  testWidgets('the record says the history does not carry the boxes', (
    tester,
  ) async {
    await pumpList(tester, [listed()]);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(IntakeDetailView), findsOneWidget);
    expect(
      find.textContaining('El historial no trae las cajas'),
      findsOneWidget,
    );
  });

  testWidgets('a capture that does carry its boxes still lists them', (
    tester,
  ) async {
    await pumpList(tester, [IntakeOut.fromJson(intakeJson())]);

    expect(find.text('1 caja'), findsOneWidget);
  });
}
