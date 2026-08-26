import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/models/box_public_out.dart';
import 'package:araguaney_app/core/api/generated/models/donation_out.dart';
import 'package:araguaney_app/core/api/generated/models/pallet_public_out.dart';
import 'package:araguaney_app/core/i18n/generated/app_localizations.dart';
import 'package:araguaney_app/features/scanning/data/scan_resolution.dart';
import 'package:araguaney_app/features/scanning/ui/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  /// The sheet is painted inside a `Scaffold` because in the application it
  /// lives over the camera, not on a screen of its own.
  Future<void> pumpResult(
    WidgetTester tester,
    ScanResolution resolution, {
    String? productName,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      home: Scaffold(
        body: ScanResultSheet(
          resolution: resolution,
          productName: productName,
          onOpen: () {},
        ),
      ),
    ),
  );

  testWidgets('a public box ficha says it is not the center record', (
    tester,
  ) async {
    await pumpResult(
      tester,
      PublicBoxFound(BoxPublicOut.fromJson(publicBoxJson())),
    );

    expect(find.text('BX-0001'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
    expect(find.text('Sellada'), findsOneWidget);
    expect(
      find.textContaining('trae menos datos que el registro del centro'),
      findsOneWidget,
    );
  });

  testWidgets('a pallet ficha shows the center and how many boxes it holds', (
    tester,
  ) async {
    await pumpResult(
      tester,
      PublicPalletFound(PalletPublicOut.fromJson(publicPalletJson())),
    );

    expect(find.text('Centro Caracas'), findsOneWidget);
    expect(find.textContaining('4 cajas'), findsOneWidget);
  });

  testWidgets('a cached box names its product when the catalog has it', (
    tester,
  ) async {
    await pumpResult(
      tester,
      CachedBoxFound(boxRow()),
      productName: 'Paracetamol 500 mg',
    );

    expect(find.text('CJ-0001'), findsOneWidget);
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
    expect(find.text('Sin sellar'), findsOneWidget);
    expect(find.text('Abrir ficha'), findsOneWidget);
  });

  testWidgets('a product the catalog lost shows nothing in its place', (
    tester,
  ) async {
    // The box's row stores the type's identifier, not its name. Showing the
    // identifier would be worse than showing nothing.
    await pumpResult(tester, CachedBoxFound(boxRow()));

    expect(find.text('CJ-0001'), findsOneWidget);
    expect(find.textContaining('pt-'), findsNothing);
  });

  testWidgets('a pallet status is read in Spanish, not as the server key', (
    tester,
  ) async {
    await pumpResult(
      tester,
      PublicPalletFound(PalletPublicOut.fromJson(publicPalletJson())),
    );

    expect(find.text('Abierta'), findsOneWidget);
    expect(find.text('OPEN'), findsNothing);
  });

  testWidgets('a donation status is read in Spanish too', (tester) async {
    await pumpResult(
      tester,
      DonationFound(DonationOut.fromJson(donationJson())),
    );

    expect(find.text('Registrada'), findsOneWidget);
    expect(find.text('REGISTERED'), findsNothing);
  });

  testWidgets('a donation leads to its record, where it is received', (
    tester,
  ) async {
    await pumpResult(
      tester,
      DonationFound(DonationOut.fromJson(donationJson())),
    );

    expect(find.text('DN-0001'), findsOneWidget);
    expect(find.textContaining('3 caja'), findsOneWidget);
    // It used to lead straight to capturing, which skips recording that it
    // arrived.
    expect(find.text('Abrir la donación'), findsOneWidget);
    // What the donor declared does not turn into boxes by itself.
    expect(
      find.textContaining('no se convierten en cajas solos'),
      findsOneWidget,
    );
  });

  testWidgets('a foreign code is reported as foreign, with what was read', (
    tester,
  ) async {
    await pumpResult(tester, const ScanNotRecognized('https://example.com/x'));

    expect(find.textContaining('no es de Araguaney'), findsOneWidget);
    expect(find.textContaining('https://example.com/x'), findsOneWidget);
  });

  testWidgets('a failure shows the operator message, not the server detail', (
    tester,
  ) async {
    await pumpResult(
      tester,
      const ScanResolutionFailed(
        NetworkFailure(message: 'SocketException: connection refused'),
      ),
    );

    expect(
      find.textContaining('No hay conexión con el servidor'),
      findsOneWidget,
    );
    expect(find.textContaining('SocketException'), findsNothing);
  });
}
