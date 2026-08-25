import 'package:araguaney_app/core/api/api_providers.dart';
import 'package:araguaney_app/core/api/generated/rest_client.dart';
import 'package:araguaney_app/core/auth/auth_providers.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/transfers/ui/transfers_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';

void main() {
  Future<void> pumpList(
    WidgetTester tester, {
    required List<Map<String, Object?>> transfers,
    String? myCenterId = 'mine',
  }) async {
    final adapter = FakeHttpAdapter((_) => FakeResponse(200, transfers));
    final container = ProviderContainer(
      overrides: [
        restClientProvider.overrideWithValue(RestClient(fakeDio(adapter))),
        myCenterIdProvider.overrideWithValue(myCenterId),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TransfersListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the header counts what waits for this centre to decide', (
    tester,
  ) async {
    // Solicitadas en las que somos el origen: es exactamente cuando el
    // servidor deja aprobar o rechazar.
    await pumpList(
      tester,
      transfers: [
        transferJson(id: 't-1', fromCenterId: 'mine', toCenterId: 'other'),
        transferJson(id: 't-2', fromCenterId: 'other', toCenterId: 'mine'),
      ],
    );

    expect(find.text('1 espera tu decisión'), findsOneWidget);
  });

  testWidgets('with nothing waiting it says so, rather than a zero', (
    tester,
  ) async {
    await pumpList(
      tester,
      transfers: [
        transferJson(
          id: 't-1',
          fromCenterId: 'mine',
          toCenterId: 'other',
          status: 'RECEIVED',
        ),
      ],
    );

    expect(find.text('Ninguna espera tu decisión'), findsOneWidget);
  });

  testWidgets('the filter is direction, because that is the first question', (
    tester,
  ) async {
    // «Viene hacia mí» y «sale de aquí» son dos trabajos distintos; el estado
    // solo importa después de saber cuál de los dos es.
    await pumpList(
      tester,
      transfers: [
        transferJson(id: 't-1', fromCenterId: 'mine', toCenterId: 'other'),
        transferJson(id: 't-2', fromCenterId: 'other', toCenterId: 'mine'),
      ],
    );

    expect(find.text('Salientes · 1'), findsOneWidget);
    expect(find.text('Entrantes · 1'), findsOneWidget);

    await tester.tap(find.text('Entrantes · 1'));
    await tester.pumpAndSettle();

    expect(find.text('Entrante'), findsOneWidget);
    expect(find.text('Saliente'), findsNothing);
  });

  testWidgets('the status is read in Spanish, not as the server key', (
    tester,
  ) async {
    await pumpList(
      tester,
      transfers: [
        transferJson(id: 't-1', fromCenterId: 'mine', toCenterId: 'other'),
      ],
    );

    expect(find.text('Solicitada'), findsOneWidget);
    expect(find.text('REQUESTED'), findsNothing);
  });

  testWidgets('the other centre is not named, because it cannot be known', (
    tester,
  ) async {
    // El contrato manda identificadores y los endpoints de centros exigen
    // administración nacional. Enseñar un identificador sería peor que nada.
    await pumpList(
      tester,
      transfers: [
        transferJson(id: 't-1', fromCenterId: 'mine', toCenterId: 'other'),
      ],
    );

    expect(find.textContaining('other'), findsNothing);
  });

  testWidgets('somebody with no centre is not told about «this centre»', (
    tester,
  ) async {
    // Una administracion nacional no pertenece a ninguno. Hablarle de «este
    // centro» describe algo que no existe.
    await pumpList(tester, transfers: const [], myCenterId: null);

    expect(find.text('No hay transferencias registradas.'), findsOneWidget);
    expect(find.textContaining('Este centro'), findsNothing);
  });
}
