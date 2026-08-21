import 'dart:convert';

import 'package:araguaney_app/features/intake/domain/queued_capture_lines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String payloadWith(List<Map<String, Object?>> boxes) =>
      jsonEncode({'capture_id': 'capture-1', 'boxes': boxes});

  test('a box reads as its product, quantity and unit', () {
    final lines = queuedCaptureLines(
      payloadWith([
        {'product_type_id': 'pt-1', 'quantity': 240, 'unit': 'unidad'},
      ]),
      {'pt-1': 'Paracetamol 500 mg'},
    );

    expect(lines, ['Paracetamol 500 mg — 240 unidad']);
  });

  test('a product the local catalog no longer has says what is known', () {
    // El nombre no está en el payload —el contrato manda identificadores— y el
    // catálogo pudo cambiar. Inventar un nombre sería peor que quedarse corto:
    // quien decide si descarta necesita datos ciertos.
    final lines = queuedCaptureLines(
      payloadWith([
        {'product_type_id': 'pt-gone', 'quantity': 60, 'unit': 'sobre'},
      ]),
      const {},
    );

    expect(lines, ['60 sobre']);
  });

  test('every box in the capture gets a line, in order', () {
    final lines = queuedCaptureLines(
      payloadWith([
        {'product_type_id': 'pt-1', 'quantity': 240, 'unit': 'unidad'},
        {'product_type_id': 'pt-2', 'quantity': 60, 'unit': 'sobre'},
      ]),
      {'pt-1': 'Paracetamol 500 mg', 'pt-2': 'Suero oral'},
    );

    expect(lines, ['Paracetamol 500 mg — 240 unidad', 'Suero oral — 60 sobre']);
  });

  test('a payload that cannot be read leaves the screen standing', () {
    // Es dato en disco: puede venir de una versión anterior. Una pantalla que
    // se cae al leer la cola deja a la persona sin ver lo que no se ha enviado,
    // que es exactamente lo contrario de para lo que existe.
    expect(queuedCaptureLines('no es json', const {}), isEmpty);
    expect(queuedCaptureLines('[]', const {}), isEmpty);
    expect(queuedCaptureLines('{"boxes":"nope"}', const {}), isEmpty);
  });
}
