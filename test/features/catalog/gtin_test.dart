import 'package:araguaney_app/features/catalog/domain/gtin.dart';
import 'package:flutter_test/flutter_test.dart';

/// El dígito de control de GS1, escrito aquí para no depender de la
/// implementación que se está probando.
int checkDigit(String payload) {
  var total = 0;
  for (var i = 0; i < payload.length; i++) {
    final weight = (payload.length - 1 - i) % 2 == 0 ? 3 : 1;
    total += int.parse(payload[i]) * weight;
  }
  return (10 - total % 10) % 10;
}

/// Un caso se construye desde el UPC-A, no desde el UPC-E.
///
/// Escribir a mano el par «este comprimido equivale a este expandido» es
/// inventar el valor esperado, y un valor inventado prueba que el código hace
/// lo que el mismo autor creyó, no lo que define el estándar. Aquí se parte de
/// un UPC-A con la forma de cada supresión, se le calcula su control, y de él
/// se extraen los seis dígitos que sobreviven en el símbolo pequeño.
({String upcE, String upcA}) caseFrom(String body, String data) {
  final upcA = '$body${checkDigit(body)}';
  return (upcE: '0$data${checkDigit(body)}', upcA: upcA);
}

void main() {
  group('a UPC-E expands to the UPC-A it stands for', () {
    final cases = {
      // El sexto dígito de datos dice qué carrera de ceros se suprimió.
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
      // Es la comprobación independiente: el control de un UPC-E se calculó
      // sobre el expandido, así que una expansión mal hecha no cuadra.
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
      // El de una caja real de las que llegan: prefijo 750, México.
      expect(gtinFromScan('7501358142600', compressed: false), '7501358142600');
    });

    test('an EAN-8 is not expanded, even though it is also eight digits', () {
      // Solo el formato del símbolo distingue un EAN-8 de un UPC-E, y por eso
      // la decisión la toma quien lee, no quien busca.
      expect(gtinFromScan('12345670', compressed: false), '12345670');
    });

    test('a code with separators keeps only its digits', () {
      expect(
        gtinFromScan('7 501358 142600', compressed: false),
        '7501358142600',
      );
    });

    test('something with no digits at all resolves to nothing', () {
      // El QR de un laboratorio: una dirección web que no identifica nada.
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
