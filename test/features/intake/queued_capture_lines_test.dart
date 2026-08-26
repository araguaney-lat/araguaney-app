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
    // The name is not in the payload — the contract sends identifiers — and the
    // catalogue may have changed. Inventing a name would be worse than falling
    // short: whoever decides whether to discard needs facts.
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
    // It is data on disk: it may come from an earlier version. A screen that
    // crashes while reading the queue leaves the person unable to see what has
    // not been sent, which is exactly the opposite of what it exists for.
    expect(queuedCaptureLines('no es json', const {}), isEmpty);
    expect(queuedCaptureLines('[]', const {}), isEmpty);
    expect(queuedCaptureLines('{"boxes":"nope"}', const {}), isEmpty);
  });
}
