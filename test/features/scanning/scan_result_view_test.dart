import 'package:araguaney_app/core/api/api_failure.dart';
import 'package:araguaney_app/core/api/generated/models/box_public_out.dart';
import 'package:araguaney_app/core/api/generated/models/donation_out.dart';
import 'package:araguaney_app/core/api/generated/models/pallet_public_out.dart';
import 'package:araguaney_app/features/scanning/data/scan_resolution.dart';
import 'package:araguaney_app/features/scanning/ui/scan_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fixtures.dart';

void main() {
  Future<void> pumpResult(WidgetTester tester, ScanResolution resolution) =>
      tester.pumpWidget(
        MaterialApp(home: ScanResultView(resolution: resolution)),
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
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('a donation says capture arrives later instead of offering it', (
    tester,
  ) async {
    await pumpResult(
      tester,
      DonationFound(DonationOut.fromJson(donationJson())),
    );

    expect(find.text('DN-0001'), findsOneWidget);
    expect(find.text('3 caja'), findsOneWidget);
    expect(
      find.textContaining('llega con la captura, en una fase siguiente'),
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
