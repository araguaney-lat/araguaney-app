import 'dart:convert';

/// What a capture waiting in the queue carries inside.
///
/// It is read from the stored payload and not from a new column because the
/// payload **is** the capture: exactly what is going to be sent, frozen since
/// before the first attempt. Reading it to show it does not rewrite it.
///
/// The contract sends product identifiers, not names, so the name is resolved
/// against the local catalogue. When the catalogue no longer has it, only what
/// is actually known is said — the quantity and its unit — because inventing a
/// name to fill the gap is worse than falling short: whoever decides whether to
/// discard this capture needs facts, not a complete-looking line.
List<String> queuedCaptureLines(
  String payload,
  Map<String, String> productNames,
) {
  final boxes = _boxesOf(payload);
  return [for (final box in boxes) _describe(box, productNames)];
}

/// This application writes the payload, but it is data on disk: it may come
/// from an earlier version or from a corrupt row, and a screen that crashes
/// while reading the queue leaves the person unable to see what has not been
/// sent.
List<Map<String, Object?>> _boxesOf(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, Object?>) return const [];
    final boxes = decoded['boxes'];
    if (boxes is! List) return const [];
    return boxes.whereType<Map<String, Object?>>().toList();
  } on FormatException {
    return const [];
  }
}

String _describe(Map<String, Object?> box, Map<String, String> productNames) {
  final quantity = box['quantity'];
  final unit = box['unit'];
  final amount = [
    if (quantity != null) '$quantity',
    if (unit is String && unit.isNotEmpty) unit,
  ].join(' ');

  final id = box['product_type_id'];
  final name = id is String ? productNames[id] : null;
  if (name == null) return amount;
  return amount.isEmpty ? name : '$name — $amount';
}
