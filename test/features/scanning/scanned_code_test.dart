import 'package:araguaney_app/features/scanning/domain/scanned_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the URL the backend puts in the QR', () {
    test('a box URL reads as a box code', () {
      final result = parseScannedCode('https://araguaney.test/b/BX-AB12CD');

      expect(result, isA<BoxCode>());
      expect((result as BoxCode).code, 'BX-AB12CD');
    });

    test('a pallet URL reads as a pallet code', () {
      final result = parseScannedCode('https://araguaney.test/p/TM-99XYZ1');

      expect((result as PalletCode).code, 'TM-99XYZ1');
    });

    test('a donation URL reads as a donation code', () {
      final result = parseScannedCode('https://araguaney.test/d/DN-7QWERT');

      expect((result as DonationCode).code, 'DN-7QWERT');
    });

    test('a deployment under a path prefix still resolves', () {
      // La ficha va en los dos últimos segmentos, no en los dos primeros.
      final result = parseScannedCode('https://araguaney.test/app/b/BX-AB12CD');

      expect((result as BoxCode).code, 'BX-AB12CD');
    });

    test('a percent-encoded code is decoded', () {
      final result = parseScannedCode('https://araguaney.test/b/BX-A%2DB');

      expect((result as BoxCode).code, 'BX-A-B');
    });
  });

  group('a bare code, printed or typed', () {
    test('each prefix routes to its kind', () {
      expect(parseScannedCode('BX-AB12CD'), isA<BoxCode>());
      expect(parseScannedCode('TM-AB12CD'), isA<PalletCode>());
      expect(parseScannedCode('DN-AB12CD'), isA<DonationCode>());
    });

    test('surrounding whitespace does not break a scan', () {
      expect(parseScannedCode('  BX-AB12CD \n'), isA<BoxCode>());
      expect((parseScannedCode(' BX-AB12CD ') as BoxCode).code, 'BX-AB12CD');
    });

    test('the prefix is matched without regard to case', () {
      expect(parseScannedCode('bx-ab12cd'), isA<BoxCode>());
    });

    test('the code is kept exactly as read', () {
      // El servidor es quien decide si existe: normalizarlo aquí sería
      // inventar una regla que el backend no pidió.
      expect((parseScannedCode('bx-ab12cd') as BoxCode).code, 'bx-ab12cd');
    });
  });

  group('when the two signals disagree', () {
    test('an unknown prefix falls back to what the path said', () {
      // Una etiqueta impresa antes de un cambio de formato sigue llevando a
      // su ficha en vez de morir en un error.
      final result = parseScannedCode('https://araguaney.test/b/BOX-LEGACY1');

      expect((result as BoxCode).code, 'BOX-LEGACY1');
    });

    test('a known prefix wins over the path it travelled in', () {
      final result = parseScannedCode('https://araguaney.test/b/TM-AB12CD');

      expect(result, isA<PalletCode>());
    });
  });

  group('anything else is reported as what it is', () {
    test('a foreign QR is not forced into a kind', () {
      final result = parseScannedCode('https://example.com/promo');

      expect((result as UnrecognizedCode).raw, 'https://example.com/promo');
    });

    test('an arbitrary string is unrecognized', () {
      expect(parseScannedCode('1234567890'), isA<UnrecognizedCode>());
    });

    test('an empty read is unrecognized rather than a crash', () {
      expect(parseScannedCode('   '), isA<UnrecognizedCode>());
    });

    test('a URL with a known path but no code is unrecognized', () {
      expect(
        parseScannedCode('https://araguaney.test/b/'),
        isA<UnrecognizedCode>(),
      );
    });
  });
}
