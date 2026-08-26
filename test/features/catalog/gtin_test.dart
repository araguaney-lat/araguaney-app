import 'package:araguaney_app/features/catalog/domain/gtin.dart';
import 'package:flutter_test/flutter_test.dart';

/// GS1's check digit, written out here so as not to depend on the
/// implementation under test.
int checkDigit(String payload) {
  var total = 0;
  for (var i = 0; i < payload.length; i++) {
    final weight = (payload.length - 1 - i) % 2 == 0 ? 3 : 1;
    total += int.parse(payload[i]) * weight;
  }
  return (10 - total % 10) % 10;
}

/// A case is built from the UPC-A, not from the UPC-E.
///
/// Writing the pair «this compressed one equals this expanded one» by hand is
/// inventing the expected value, and an invented value proves the code does
/// what its own author believed, not what the standard defines. Here we start
/// from a UPC-A with the shape of each suppression, compute its check digit,
/// and from it take the six digits that survive in the small symbol.
({String upcE, String upcA}) caseFrom(String body, String data) {
  final upcA = '$body${checkDigit(body)}';
  return (upcE: '0$data${checkDigit(body)}', upcA: upcA);
}

void main() {
  group('a UPC-E expands to the UPC-A it stands for', () {
    final cases = {
      // The sixth data digit says which run of zeros was suppressed.
      'ends in 0, 1 or 2': caseFrom('01200000345', '123450'),
      'ends in 3': caseFrom('01230000041', '123413'),
      'ends in 4': caseFrom('01234000007', '123474'),
      'ends in 5 through 9': caseFrom('01234500006', '123456'),
    };

    for (final entry in cases.entries) {
      test(entry.key, () {
        expect(expandUpcE(entry.value.upcE), entry.value.upcA);
      });
    }

    test('what comes out carries a valid check digit', () {
      // It is the independent check: a UPC-E's check digit was computed over
      // the expanded one, so a badly done expansion does not add up.
      for (final c in cases.values) {
        final expanded = expandUpcE(c.upcE);
        expect(
          checkDigit(expanded.substring(0, 11)),
          int.parse(expanded[11]),
          reason: '${c.upcE} → $expanded',
        );
      }
    });
  });

  group('what is left alone', () {
    test('an EAN-13 passes through untouched', () {
      // That of a real box of the kind that arrives: prefix 750, Mexico.
      expect(gtinFromScan('7501358142600', compressed: false), '7501358142600');
    });

    test('an EAN-8 is not expanded, even though it is also eight digits', () {
      // Only the symbol's format tells an EAN-8 from a UPC-E, and that is why
      // the decision is taken by whoever reads, not by whoever looks up.
      expect(gtinFromScan('12345670', compressed: false), '12345670');
    });

    test('a code with separators keeps only its digits', () {
      expect(
        gtinFromScan('7 501358 142600', compressed: false),
        '7501358142600',
      );
    });

    test('something with no digits at all resolves to nothing', () {
      // A laboratory's QR: a web address that identifies nothing.
      expect(
        gtinFromScan('https://nartex.example/simplex', compressed: false),
        isNull,
      );
    });

    test('a malformed UPC-E is returned as it came, not invented', () {
      expect(expandUpcE('123'), '123');
      expect(expandUpcE('92345678'), '92345678');
    });
  });
}
